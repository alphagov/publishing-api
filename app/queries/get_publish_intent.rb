module Queries
  module GetPublishIntent
    class << self
      def call(base_path)
        response = content_store.get_publish_intent(base_path)
        response.to_hash.deep_symbolize_keys
      rescue GdsApi::TimedOutException
        raise_error(500, "The live content store timed out requesting publish intent")
      rescue GdsApi::HTTPNotFound
        raise_error(404, "Could not find a publish intent for #{base_path}")
      end

    private

      def content_store
        PublishingAPI.service(:live_content_store)
      end

      def raise_error(code, message)
        raise CommandError.new(
          code:,
          error_details: {
            error: {
              code:,
              message:,
            },
          },
        )
      end
    end
  end
end
