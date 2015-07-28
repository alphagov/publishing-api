class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

private

  def base_path
    "/#{params[:base_path]}"
  end

  def content_item
    @content_item ||= JSON.parse(request.body.read)
  rescue JSON::ParserError
    head :bad_request
  end
end
