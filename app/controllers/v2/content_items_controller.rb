module V2
  class ContentItemsController < ApplicationController
    def put_content
      response = command_processor.put_content(payload.merge(content_id: params[:content_id]))
      render status: response.code, json: response.as_json
    end

  private
    def command_processor
      CommandProcessor.new(nil)
    end

    def payload
      @payload ||= JSON.parse(request.body.read).deep_symbolize_keys
    rescue JSON::ParserError
      head :bad_request
    end
  end
end
