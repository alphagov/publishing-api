module Adapters
  class UrlArbiter
    def self.call(base_path, publishing_app)
      PublishingAPI.service(:url_arbiter).reserve_path(
        base_path,
        publishing_app: publishing_app
      )
    rescue GOVUK::Client::Errors::BaseError => e
      if e.is_a?(GOVUK::Client::Errors::Conflict)
        raise_already_in_use!(e)
      elsif e.is_a?(GOVUK::Client::Errors::HTTPError) && [422, 409].include?(e.code)
        raise CommandError.new(code: e.code, error_details: e.response)
      elsif e.is_a?(GOVUK::Client::Errors::InvalidPath)
        raise_invalid_path!(e)
      else
        raise CommandError.new(code: 500, message: "Unexpected error whilst registering with url-arbiter: #{e}")
      end
    end

  private
    def self.raise_already_in_use!(e)
      path_errors = e.response.fetch("errors").fetch("path")
      message = "#{e.response.fetch("path")} is reserved"

      error_details = {
        error: {
          code: 409,
          message: message,
          fields: {
            base_path: path_errors,
          },
        }
      }

      raise CommandError.new(code: 409, error_details: error_details)
    end

    def self.raise_invalid_path!(e)
      error_details = {
        error: {
          code: 422,
          message: e.message,
          fields: {
            base_path: ["is invalid"]
          }
        }
      }

      raise CommandError.new(code: 422, error_details: error_details)
    end
  end
end
