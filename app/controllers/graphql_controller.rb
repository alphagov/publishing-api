# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  skip_before_action :authenticate_user!, only: [:execute]

  def execute
    execute_in_read_replica do
      variables = prepare_variables(params[:variables])
      query = params[:query]
      operation_name = params[:operationName]
      context = {
        # Query context goes here, for example:
        # current_user: current_user,
      }
      result = PublishingApiSchema.execute(
        query,
        variables:,
        context:,
        operation_name:,
      ).to_hash

      set_prometheus_labels(result.dig("data", "edition"))

      if result.key?("errors")
        logger.warn("GraphQL query result contained errors: #{result['errors']}")
      else
        logger.debug("GraphQL query result: #{result}")
      end

      render json: result
    rescue StandardError => e
      raise e unless Rails.env.development?

      handle_error_in_development(e)
    end
  end

private

  def execute_in_read_replica(&block)
    if Rails.env.production_replica?
      ActiveRecord::Base.connected_to(role: :reading, prevent_writes: true) do
        yield block
      end
    else
      yield block
    end
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: { errors: [{ message: error.message, backtrace: error.backtrace }], data: {} }, status: :internal_server_error
  end

  def set_prometheus_labels(edition)
    prometheus_labels = request.env.fetch("govuk.prometheus_labels", {})

    request.env["govuk.prometheus_labels"] = prometheus_labels.merge(
      document_type: edition["document_type"],
      schema_name: edition["schema_name"],
    )
  end
end
