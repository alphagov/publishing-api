class CommandError < StandardError
  attr_reader :code, :error_details

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
