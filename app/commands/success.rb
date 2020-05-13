module Commands
  class Success
    attr_reader :data, :message, :code

    def initialize(data, message: "OK", code: 200)
      @message = message
      @data = data
      @code = code
    end

    def as_json(_options = nil)
      data
    end

    def ok?
      true
    end

    def error?
      false
    end

    def client_error?
      false
    end

    def server_error?
      false
    end
  end
end
