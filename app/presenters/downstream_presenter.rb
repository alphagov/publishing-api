require 'queries/get_web_content_items'

module Presenters
  class DownstreamPresenter
    def self.present(web_content_item, state_fallback_order:)
      if web_content_item.is_a?(ContentItem)
        # TODO: Add deprecation notice here once we start to migrate other parts of
        # the app to use WebContentItem. Adding a notice now would be too noisy
        web_content_item = ::Queries::GetWebContentItems.(web_content_item.id).first
      end

      link_set = LinkSet.find_by(content_id: web_content_item.content_id)
      new(web_content_item, link_set, state_fallback_order: state_fallback_order).present
    end

    def initialize(web_content_item, link_set, state_fallback_order:)
      self.web_content_item = web_content_item
      self.link_set = link_set
      self.state_fallback_order = state_fallback_order
    end

    def present
      symbolized_attributes
        .except(*%i{last_edited_at id state user_facing_version}) # only intended to be used by publishing applications
        .merge(first_published_at)
        .merge(public_updated_at)
        .merge(links)
        .merge(access_limited)
        .merge(format)
        .merge(withdrawal_notice)
    end

  private

    attr_accessor :web_content_item, :link_set, :state_fallback_order

    def symbolized_attributes
      SymbolizeJSON.symbolize(web_content_item.as_json.merge(description: web_content_item.description))
    end

    def links
      return {} unless link_set

      if MigrateExpandedLinks.document_types.include?(web_content_item.document_type)
        {
          links: expanded_link_set_presenter.links,
        }
      else
        {
          links: link_set_presenter.links,
          expanded_links: expanded_link_set_presenter.links,
        }
      end
    end

    def access_limited
      return {} unless access_limit
      {
        access_limited: {
          users: access_limit.users
        }
      }
    end

    def link_set_presenter
      Presenters::Queries::LinkSetPresenter.new(link_set)
    end

    def expanded_link_set_presenter
      Presenters::Queries::ExpandedLinkSet.new(
        content_id: web_content_item.content_id,
        state_fallback_order: state_fallback_order,
        locale_fallback_order: locale_fallback_order
      )
    end

    def access_limit
      @access_limit ||= AccessLimit.find_by(content_item_id: web_content_item.id)
    end

    def locale_fallback_order
      [web_content_item.locale, ContentItem::DEFAULT_LOCALE].uniq
    end

    def first_published_at
      if web_content_item.first_published_at.present?
        { first_published_at: web_content_item.first_published_at }
      else
        {}
      end
    end

    def public_updated_at
      return {} unless web_content_item.public_updated_at.present?
      { public_updated_at: web_content_item.public_updated_at }
    end

    def base_path
      { base_path: web_content_item.base_path }
    end

    def locale
      { locale: web_content_item.locale }
    end

    def format
      { format: web_content_item.schema_name }
    end

    def withdrawal_notice
      unpublishing = Unpublishing.find_by(content_item_id: web_content_item.id)

      if unpublishing && unpublishing.withdrawal?
        {
          withdrawn_notice: {
            explanation: unpublishing.explanation,
            withdrawn_at: unpublishing.created_at.iso8601,
          },
        }
      else
        {}
      end
    end

    class V1
      def self.present(attributes, event, update_type: true, payload_version: true)
        attributes = attributes.except(:update_type) unless update_type
        attributes.merge!(payload_version: event.id) if payload_version
        attributes
      end
    end
  end
end
