module Presenters
  class EditionPresenter
    NON_PRESENTED_PROPERTIES = %i[
      api_path
      api_url
      auth_bypass_ids
      content_store
      created_at
      document_id
      id
      last_edited_at
      last_edited_by_editor_id
      publishing_api_first_published_at
      major_published_at
      published_at
      publishing_api_last_edited_at
      publishing_request_id
      publishing_api_first_published_at
      publishing_api_last_edited_at
      state
      unpublishing_type
      updated_at
      user_facing_version
      web_url
      withdrawn
    ].freeze

    def initialize(edition, draft: false)
      @edition = edition
      @draft = draft
    end

    def for_content_store(payload_version)
      present.except(:update_type).merge(payload_version:)
    end

    def for_message_queue(payload_version)
      present.merge(
        govuk_request_id: GdsApi::GovukHeaders.headers[:govuk_request_id],
        links: unexpanded_links,
        payload_version:,
      )
    end

    def present
      edition.to_h
        .except(*NON_PRESENTED_PROPERTIES)
        .merge(auth_bypass_ids)
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

    def auth_bypass_ids
      return {} unless draft

      { auth_bypass_ids: edition.auth_bypass_ids || [] }
    end

    def unexpanded_links
      links = ::Queries::LinksForEditionIds.new([edition.id]).merged_links
      links[edition.id].symbolize_keys
    end

    def expanded_links_attributes
      {
        expanded_links:,
      }
    end

    def access_limited
      return {} unless access_limit

      if edition.state != "draft"
        GovukError.notify(
          "Tried to send non-draft item with access_limited data",
          level: "warning",
          extra: { content_id: edition.content_id },
        )
        {}
      else
        {
          access_limited: {
            users: access_limit.users,
            organisations: access_limit.organisations,
          },
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
        edition,
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
        document_type: edition.document_type,
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
            withdrawn_at:,
          },
        }
      else
        {}
      end
    end

    def publishing_request_id
      if edition.publishing_request_id
        {
          publishing_request_id: edition.publishing_request_id,
        }
      else
        {}
      end
    end
  end
end
