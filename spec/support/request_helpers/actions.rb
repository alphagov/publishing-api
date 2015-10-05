module RequestHelpers
  module Actions
    def do_request(body: request_body)
      put request_path, body
    end
  end
end

RSpec.configuration.include RequestHelpers::Actions, :type => :request
