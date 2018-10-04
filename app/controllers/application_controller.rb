class ApplicationController < ActionController::API
  include GDS::SSO::ControllerMethods

  rescue_from ActionController::ParameterMissing, with: :parameter_missing_error
  rescue_from JSON::ParserError, with: :json_parse_error
  rescue_from CommandError, with: :respond_with_command_error

  before_action :authenticate_user!

  Warden::Manager.after_authentication do |user, _, _|
    user.set_app_name!
  end

private

  def parameter_missing_error(error)
    error = CommandError.new(code: 422, error_details: {
      error: {
        code: 422,
        message: error.message
      }
    })

    respond_with_command_error(error)
  end

  def json_parse_error(error)
    error = CommandError.new(code: 400, error_details: {
      error: {
        code: 400,
        message: error.message
      }
    })

    respond_with_command_error(error)
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

  def path_params
    @path_params ||= ActionController::Parameters.new(request.path_parameters)
  end
end
