module RequestHelpers
  def cache_control
    Rack::Cache::CacheControl.new(response["Cache-Control"])
  end

  def default_ttl
    Rails.application.config.default_ttl
  end

  # Use in request and controller specs to access the response.
  def parsed_response
    JSON.parse(response.body)
  end
end

RSpec.configuration.include RequestHelpers
