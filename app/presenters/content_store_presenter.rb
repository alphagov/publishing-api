module Presenters
  class ContentStorePresenter
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
        .except(:id, :update_type)
        .merge(public_updated_at)
        .merge(links)
        .merge(transmitted_at)
    end

    private

    attr_accessor :content_item, :link_set

    def symbolized_attributes
      content_item.as_json.deep_symbolize_keys
    end

    def links
      if link_set
        { links: link_set.links }
      else
        {}
      end
    end

    def public_updated_at
      if content_item.public_updated_at.present?
        { public_updated_at: content_item.public_updated_at.iso8601 }
      else
        {}
      end
    end

    def transmitted_at
      { transmitted_at: Time.new.to_f }
    end

    class V1
      def self.present(attributes, access_limited: true, update_type: true, transmitted_at: true)
        unless access_limited
          attributes = attributes.except(:access_limited)
        end

        unless update_type
          attributes = attributes.except(:update_type)
        end

        if transmitted_at
          attributes = attributes.merge(transmitted_at: Time.new.to_f)
        end

        attributes
      end
    end
  end
end
