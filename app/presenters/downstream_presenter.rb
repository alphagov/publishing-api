module Presenters
  class DownstreamPresenter
    attr_accessor :link_set

    def self.present(edition, draft: false)
      return {} unless edition

      new(edition, nil, draft: draft).present
    end

    def initialize(edition, link_set = nil, draft: false)
      self.edition = edition
      self.link_set = link_set || LinkSet.find_by(content_id: edition.content_id)
      self.draft = draft
    end

    def present
      symbolized_attributes
        .except(*%i{updated_at created_at document_id content_store last_edited_at id state user_facing_version api_url web_url withdrawn api_path unpublishing_type}) # only intended to be used by publishing applications
        .merge(rendered_details)
        .merge(links)
        .merge(access_limited)
        .merge(format)
        .merge(withdrawal_notice)
    end

  private

    attr_accessor :edition, :draft

    def symbolized_attributes
      ContentItem.new(edition).present
    end

    def links
      {
        expanded_links: expanded_link_set_presenter.links,
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
            fact_check_ids: access_limit.fact_check_ids,
          }
        }
      end
    end

    def expanded_link_set_presenter
      @expanded_link_set_presenter ||= Presenters::Queries::ExpandedLinkSet.new(
        content_id: edition.content_id,
        draft: draft,
        locale_fallback_order: locale_fallback_order
      )
    end

    def details_presenter
      @details_presenter ||= Presenters::DetailsPresenter.new(
        symbolized_attributes[:details],
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

    def locale_fallback_order
      [edition.locale, Edition::DEFAULT_LOCALE].uniq
    end

    def rendered_details
      { details: details_presenter.details }
    end

    def format
      {
        format: edition.schema_name,
        schema_name: edition.schema_name,
        document_type: edition.document_type
      }
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
  end
end
