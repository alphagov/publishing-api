require 'queries/get_web_content_items'

module Presenters
  class DownstreamPresenter
    attr_accessor :link_set

    def self.present(web_content_item, state_fallback_order:)
      return {} unless web_content_item
      if web_content_item.is_a?(Edition)
        # TODO: Add deprecation notice here once we start to migrate other parts of
        # the app to use WebContentItem. Adding a notice now would be too noisy
        web_content_item = ::Queries::GetWebContentItems.(web_content_item.id).first
      end

      new(web_content_item, nil, state_fallback_order: state_fallback_order).present
    end

    def initialize(web_content_item, link_set = nil, state_fallback_order:)
      self.web_content_item = web_content_item
      self.link_set = link_set || LinkSet.find_by(content_id: web_content_item.content_id)
      self.state_fallback_order = state_fallback_order
    end

    def present
      symbolized_attributes
        .except(*%i{last_edited_at id state user_facing_version api_url web_url unpublishing_type}) # only intended to be used by publishing applications
        .merge(rendered_details)
        .merge(links)
        .merge(access_limited)
        .merge(format)
        .merge(withdrawal_notice)
    end

  private

    attr_accessor :web_content_item, :state_fallback_order

    def symbolized_attributes
      SymbolizeJSON.symbolize(web_content_item.as_json.merge(description: web_content_item.description))
    end

    def links
      {
        expanded_links: expanded_link_set_presenter.links,
      }
    end

    def access_limited
      return {} unless access_limit
      if web_content_item.state != 'draft'
        Airbrake.notify(
          'Tried to send non-draft item with access_limited data',
          content_id: web_content_item.content_id
        )
        {}
      else
        {
          access_limited: {
            users: access_limit.users
          }
        }
      end
    end

    def expanded_link_set_presenter
      @expanded_link_set_presenter ||= Presenters::Queries::ExpandedLinkSet.new(
        content_id: web_content_item.content_id,
        state_fallback_order: state_fallback_order,
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
        Presenters::ChangeHistoryPresenter.new(web_content_item)
    end

    def access_limit
      @access_limit ||= AccessLimit.find_by(edition_id: web_content_item.id)
    end

    def locale_fallback_order
      [web_content_item.locale, Edition::DEFAULT_LOCALE].uniq
    end

    def rendered_details
      { details: details_presenter.details }
    end

    def format
      {
        format: web_content_item.schema_name,
        schema_name: web_content_item.schema_name,
        document_type: web_content_item.document_type
      }
    end

    def withdrawal_notice
      unpublishing = Unpublishing.find_by(edition_id: web_content_item.id)

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
