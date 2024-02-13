# Safely call out to content store and translate any http errors
# to
module Adapters
  class ContentStore
    def self.put_content_item(base_path, content_item)
      ci = ContentItem.find_or_create_by!(content_store: 'live', base_path:)
      ci.update!(content_item)
    end

    def self.put_publish_intent(base_path, publish_intent)
      pi = PublishIntent.find_or_create_by!(base_path:)
      pi.update!(publish_intent)
    end

    def self.delete_content_item(base_path)
      ci = ContentItem.live.find_by(base_path:)
      ci.delete!
    end
  end
end
