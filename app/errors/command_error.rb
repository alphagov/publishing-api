class CommandError < StandardError
  attr_reader :code, :error_details

  def self.with_error_handling(&block)
    block.call
  rescue GdsApi::HTTPServerError => e
    should_suppress = (PublishingAPI.swallow_connection_errors && e.code == 502)
    raise CommandError.new(code: e.code, message: e.message) unless should_suppress
  rescue GdsApi::HTTPClientError => e
    raise CommandError.new(code: e.code, error_details: {
      error: {
        code: e.code,
        message: e.message,
        fields: e.error_details.fetch('errors', {})
      }
    })
  rescue GdsApi::BaseError => e
    raise CommandError.new(code: 500, message: "Unexpected error from the downstream application: #{e.message}")
  end

  # error_details: Hash(field_name: String => [error_messages]: Array(String))
  def initialize(code:, message: nil, error_details: nil)
    raise "Invalid code #{code}" unless valid_code?(code)
    @code = code
    @error_details = if error_details
      error_details
    elsif message
      {
        "error" => {
          "code" => code,
          "message" => message,
        }
      }
    else
      {
        "error" => {
          "code" => code,
        }
      }
    end
    super(message || error_details.to_s)
  end

  def valid_code?(code)
    [400, 404, 409, 422, 500].include?(code)
  end

  def as_json(options = nil)
    @error_details
  end

  def ok?; false; end
  def error?; true; end

  # True if this error represents a client error, ie. the problem lies with
  # request sent by the caller to the publishing API
  def client_error?
    (400..499).cover?(code)
  end

  # True if this error represents a server error, ie. the server had an
  # unexpected problem which meant that it was unable to process the
  # request. The request has not been processed and the client should retry.
  def server_error?
    (500..599).cover?(code)
  end
end
