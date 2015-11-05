module Presenters
  class ContentStorePresenter
    def self.present(content_item)
      version = Version.find_by!(target: content_item)
      link_set = LinkSet.find_by(content_id: content_item.content_id)

      new(content_item, version, link_set).present
    end

    def initialize(content_item, version, link_set)
      self.content_item = content_item
      self.version = version
      self.link_set = link_set
    end

    def present
      symbolized_attributes
        .slice(*content_item.class::TOP_LEVEL_FIELDS)
        .except(:id, :update_type)
        .merge(public_updated_at)
        .merge(links)
        .merge(version_number)
    end

    private

    attr_accessor :content_item, :version, :link_set

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

    def version_number
      { version: version.number }
    end

    def public_updated_at
      if content_item.public_updated_at.present?
        { public_updated_at: content_item.public_updated_at.iso8601 }
      else
        {}
      end
    end
  end
end
