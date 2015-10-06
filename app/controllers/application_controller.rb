class ApplicationController < ActionController::Base
  class BadRequest < StandardError; end

  rescue_from Command::Error, with: :respond_with_command_error
  rescue_from BadRequest do
    head :bad_request
  end

private
  def respond_with_command_error(error)
    render status: error.code, json: error.as_json
  end

  def base_path
    "/#{params[:base_path]}"
  end

  def payload
    @payload ||= JSON.parse(request.body.read).deep_symbolize_keys
  rescue JSON::ParserError
    raise BadRequest
  end

  def content_item
    payload
  end
end
