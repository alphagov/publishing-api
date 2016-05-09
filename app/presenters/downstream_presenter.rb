module Presenters
  class DownstreamPresenter
    def self.present(content_item, fallback_order:)
      link_set = LinkSet.find_by(content_id: content_item.content_id)
      new(content_item, link_set, fallback_order: fallback_order).present
    end

    def initialize(content_item, link_set, fallback_order:)
      self.content_item = content_item
      self.link_set = link_set
      self.fallback_order = fallback_order
    end

    def present
      symbolized_attributes
        .slice(*content_item.class::TOP_LEVEL_FIELDS)
        .merge(first_published_at)
        .merge(public_updated_at)
        .merge(links)
        .merge(access_limited)
        .merge(base_path)
        .merge(locale)
        .merge(withdrawal_notice)
    end

  private

    attr_accessor :content_item, :link_set, :fallback_order

    def symbolized_attributes
      content_item.as_json.symbolize_keys
    end

    def links
      return {} unless link_set
      {
        links: link_set_presenter.links,
        expanded_links: expanded_link_set_presenter.links
      }
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
        link_set: link_set,
        fallback_order: fallback_order,
      )
    end

    def access_limit
      @access_limit ||= AccessLimit.find_by(content_item: content_item)
    end

    def web_content_item
      @web_content_item ||= WebContentItem.new(content_item)
    end

    def first_published_at
      if content_item.first_published_at.present?
        { first_published_at: content_item.first_published_at.iso8601 }
      else
        {}
      end
    end

    def public_updated_at
      return {} unless content_item.public_updated_at.present?
      { public_updated_at: content_item.public_updated_at.iso8601 }
    end

    def base_path
      { base_path: web_content_item.base_path }
    end

    def locale
      { locale: web_content_item.locale }
    end

    def withdrawal_notice
      unpublishing = Unpublishing.find_by(content_item: content_item)

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
