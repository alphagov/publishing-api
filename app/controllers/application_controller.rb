class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

private

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
