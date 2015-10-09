module Queries
  module GetPublishIntent
    def self.call(base_path)
      PublishingAPI.service(:live_content_store).get_publish_intent(base_path)
    end
  end
end
