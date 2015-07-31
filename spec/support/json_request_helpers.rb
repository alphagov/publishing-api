module JSONRequestHelper
  def put_json(path, attrs, headers = {})
    put path, attrs.to_json, {"CONTENT_TYPE" => "application/json"}.merge(headers)
  end
end

RSpec.configuration.include JSONRequestHelper, :type => :request
