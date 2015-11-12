module RequestHelpers
  module Actions
    def do_request(body: request_body, headers: {})
      case request_method
      when :put
        put request_path, body, headers
      when :get
        get request_path, body, headers
      when :post
        post request_path, body, headers
      else
        raise "Unsupported request_method"
      end
    end
  end
end

RSpec.configuration.include RequestHelpers::Actions, :type => :request
