module RequestHelpers
  # Use in request and controller specs to access the response.
  def parsed_response
    JSON.parse(response.body)
  end
end

RSpec.configuration.include RequestHelpers
