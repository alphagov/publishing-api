class ApplicationController < ActionController::Base
  include GDS::SSO::ControllerMethods

  rescue_from ActionController::ParameterMissing, with: :parameter_missing_error
  rescue_from JSON::ParserError, with: :json_parse_error
  rescue_from CommandError, with: :respond_with_command_error

  before_action do
    # Force Rails to show text-error pages
    request.env['HTTP_X_REQUESTED_WITH'] = 'XMLHttpRequest'
  end

  before_action :require_signin_permission!

  Warden::Manager.after_authentication do |user, _, _|
    user.set_app_name!
  end

private

  def parameter_missing_error(e)
    error = CommandError.new(code: 422, error_details: {
      error: {
        code: 422,
        message: e.message
      }
    })

    respond_with_command_error(error)
  end

  def json_parse_error(e)
    error = CommandError.new(code: 400, error_details: {
      error: {
        code: 400,
        message: e.message
      }
    })

    respond_with_command_error(error)
  end

  def validate_uuid(uuid)
    return true if uuid =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
  end

  def ensure_valid_content_id
    raise CommandError.new(code: 400, error_details: {
      error: {
        code: 400,
        message: "Invalid Content ID"
      }
    }) unless validate_uuid path_params[:content_id]
  end

  def respond_with_command_error(error)
    error = error.cause unless error.is_a?(CommandError)
    render status: error.code, json: error
  end

  def base_path
    "/#{params[:base_path]}"
  end

  def payload
    @payload ||= JSON.parse(request.body.read).deep_symbolize_keys
  end

  def query_params
    @query_params ||= ActionController::Parameters.new(request.query_parameters)
  end

  def post_params
    @post_params ||= ActionController::Parameters.new(request.request_parameters)
  end

  def path_params
    @post_params ||= ActionController::Parameters.new(request.path_parameters)
  end
end
