module Commands
  class DeletePublishIntent < BaseCommand
    def call
      PublishingAPI.service(:live_content_store).delete_publish_intent(base_path)

      Success.new({})
    rescue GdsApi::HTTPServerError => e
      raise CommandError.new(code: e.code, message: e.message)
    rescue GdsApi::HTTPClientError => e
      raise CommandError.new(code: e.code, error_details: convert_error_details(e))
    rescue GdsApi::BaseError => e
      raise CommandError.new(code: 500, message: "Unexpected error from content store: #{e.message}")
    end

  private
    def convert_error_details(upstream_error)
      {
        error: {
          code: upstream_error.code,
          message: upstream_error.message,
          fields: upstream_error.error_details.fetch('errors', {})
        }
      }
    end
  end
end
