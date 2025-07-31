module RequestHelpers
  def cache_control
    Rack::Cache::CacheControl.new(response["Cache-Control"])
  end

  # Use in request and controller specs to access the response.
  def parsed_response
    JSON.parse(response.body)
  end
end

RSpec.configuration.include RequestHelpers
