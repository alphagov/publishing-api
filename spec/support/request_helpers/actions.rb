module RequestHelpers
  module Actions
    def put_content_item(body: content_item.to_json)
      put request_path, body
    end
  end
end

RSpec.configuration.include RequestHelpers::Actions, :type => :request
