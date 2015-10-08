module RequestHelpers
  module Actions
    def do_request(body: request_body)
      case request_method
      when :put
        put request_path, body
      when :get
        get request_path, body
      end
    end
  end
end

RSpec.configuration.include RequestHelpers::Actions, :type => :request
