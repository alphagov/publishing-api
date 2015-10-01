module RequestHelpers
  module Actions
    def do_request(body: content_item.to_json)
      put request_path, body
    end
  end
end

RSpec.configuration.include RequestHelpers::Actions, :type => :request
