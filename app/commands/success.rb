module Commands
  class Success
    attr_reader :data, :message

    def initialize(data, message: "OK")
      @message = message
      @data = data
    end

    def code
      200
    end

    def as_json(options = nil)
      data
    end

    def ok?; true; end
    def error?; false; end
    def client_error?; false; end
    def server_error?; false; end
  end
end
