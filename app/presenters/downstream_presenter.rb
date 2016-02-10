module Presenters
  class DownstreamPresenter
    def self.present(content_item)
      link_set = LinkSet.find_by(content_id: content_item.content_id)
      new(content_item, link_set).present
    end

    def initialize(content_item, link_set)
      self.content_item = content_item
      self.link_set = link_set
    end

    def present
      symbolized_attributes
        .slice(*content_item.class::TOP_LEVEL_FIELDS)
        .merge(public_updated_at)
        .merge(links)
        .merge(access_limited)
        .merge(transmitted_at)
        .merge(base_path)
        .merge(locale)
    end

  private
    attr_accessor :content_item, :link_set

    def symbolized_attributes
      content_item.as_json.symbolize_keys
    end

    def links
      if link_set
        { links: link_set_presenter.links }
      else
        {}
      end
    end

    def access_limited
      if access_limit
        {
          access_limited: {
            users: access_limit.users
          }
        }
      else
        {}
      end
    end

    def link_set_presenter
      Presenters::Queries::LinkSetPresenter.new(link_set)
    end

    def access_limit
      @access_limit ||= AccessLimit.find_by(content_item: content_item)
    end

    def location
      @location ||= Location.find_by!(content_item: content_item)
    end

    def translation
      @translation ||= Translation.find_by!(content_item: content_item)
    end

    def public_updated_at
      if content_item.public_updated_at.present?
        { public_updated_at: content_item.public_updated_at.iso8601 }
      else
        {}
      end
    end

    def base_path
      { base_path: location.base_path }
    end

    def locale
      { locale: translation.locale }
    end

    def transmitted_at
      { transmitted_at: DateTime.now.to_s(:nanoseconds) }
    end

    class V1
      def self.present(attributes, update_type: true, transmitted_at: true)
        attributes = attributes.except(:update_type) unless update_type
        attributes = attributes.merge(transmitted_at: DateTime.now.to_s(:nanoseconds)) if transmitted_at

        attributes
      end
    end
  end
end
