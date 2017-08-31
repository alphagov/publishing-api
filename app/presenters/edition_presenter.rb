module Presenters
  class EditionPresenter
    NON_PRESENTED_PROPERTIES = [
      :api_path,
      :api_url,
      :content_store,
      :created_at,
      :document_id,
      :id,
      :last_edited_at,
      :major_published_at,
      :publisher_first_published_at,
      :publisher_major_published_at,
      :publisher_published_at,
      :publisher_last_edited_at,
      :publishing_request_id,
      :state,
      :temporary_first_published_at,
      :temporary_major_published_at,
      :temporary_published_at,
      :temporary_last_edited_at,
      :unpublishing_type,
      :updated_at,
      :user_facing_version,
      :web_url,
      :withdrawn,
    ].freeze

    def initialize(edition, draft: false)
      @edition = edition
      @draft = draft
    end

    def for_content_store(payload_version)
      present.except(:update_type).merge(payload_version: payload_version)
    end

    def for_message_queue(payload_version)
      present.merge(
        govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
        links: unexpanded_links,
        payload_version: payload_version
      )
    end

    def present
      edition.to_h
        .except(*NON_PRESENTED_PROPERTIES)
        .merge(rendered_details)
        .merge(expanded_links_attributes)
        .merge(access_limited)
        .merge(schema_name_and_document_type)
        .merge(document_supertypes)
        .merge(withdrawal_notice)
        .merge(publishing_request_id)
    end

    def expanded_links
      expanded_link_set_presenter.links
    end

    def rendered_details
      { details: details_presenter.details }
    end

  private

    attr_reader :draft, :edition

    def unexpanded_links
      Queries::LinkSetPresenter.new(
        LinkSet.find_by(content_id: edition.content_id)
      ).links
    end

    def expanded_links_attributes
      {
        expanded_links: expanded_links
      }
    end

    def access_limited
      return {} unless access_limit
      if edition.state != 'draft'
        Airbrake.notify(
          'Tried to send non-draft item with access_limited data',
          content_id: edition.content_id
        )
        {}
      else
        {
          access_limited: {
            users: access_limit.users,
            auth_bypass_ids: access_limit.auth_bypass_ids,
          }
        }
      end
    end

    def expanded_link_set_presenter
      @expanded_link_set_presenter ||= Presenters::Queries::ExpandedLinkSet.by_edition(
        edition,
        with_drafts: draft,
      )
    end

    def details_presenter
      @details_presenter ||= Presenters::DetailsPresenter.new(
        edition.to_h[:details],
        change_history_presenter,
      )
    end

    def change_history_presenter
      @change_history_presenter ||=
        Presenters::ChangeHistoryPresenter.new(edition)
    end

    def access_limit
      @access_limit ||= AccessLimit.find_by(edition_id: edition.id)
    end

    def schema_name_and_document_type
      {
        schema_name: edition.schema_name,
        document_type: edition.document_type
      }
    end

    def document_supertypes
      GovukDocumentTypes.supertypes(document_type: edition.document_type)
    end

    def withdrawal_notice
      unpublishing = edition.unpublishing

      if unpublishing && unpublishing.withdrawal?
        withdrawn_at = (unpublishing.unpublished_at || unpublishing.created_at).iso8601
        {
          withdrawn_notice: {
            explanation: unpublishing.explanation,
            withdrawn_at: withdrawn_at
          },
        }
      else
        {}
      end
    end

    def publishing_request_id
      if edition.publishing_request_id
        {
          publishing_request_id: edition.publishing_request_id
        }
      else
        {}
      end
    end
  end
end
