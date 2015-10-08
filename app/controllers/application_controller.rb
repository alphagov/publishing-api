class ApplicationController < ActionController::Base
  rescue_from Command::Error, with: :respond_with_command_error

private
  def respond_with_command_error(error)
    render status: error.code, json: error.as_json
  end

  def base_path
    "/#{params[:base_path]}"
  end

  def parse_content_item
    @content_item = JSON.parse(request.body.read).deep_symbolize_keys
  rescue JSON::ParserError
    head :bad_request
  end

  attr_reader :content_item
end
