class UrlArbitrationError < StandardError
  attr_reader :upstream_error

  def initialize(upstream_error)
    @upstream_error = upstream_error
  end

  def propagate_directly?
    [422, 409].include?(upstream_error.code)
  end

  def code
    propagate_directly? ? upstream_error.code : 500
  end

  def error_details
    if propagate_directly?
      upstream_error.response
    else
      {
        message: "Unexpected error whilst registering with url-arbiter: #{upstream_error.message}"
      }
    end
  end
end
