# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  skip_before_action :authenticate_user!, only: [:execute]
  before_action :set_cors_headers, only: [:live_content]

  def live_content
    execute_in_read_replica do
      begin
        encoded_base_path = Addressable::URI.encode(params[:base_path])

        schema_name = Edition.live.find_by(base_path: encoded_base_path)&.schema_name

        unless schema_name
          set_cache_headers
          return head :not_found
        end

        klass = "queries/graphql/#{schema_name}_query".camelize.constantize

        query = klass.query(base_path: encoded_base_path)
        result = PublishingApiSchema.execute(query).to_hash
        process_graphql_result(result)

        content_item = result.dig("data", "edition")

        set_cache_headers
        render json: content_item
      end
    rescue NameError
      return head :not_found
    rescue Addressable::URI::InvalidURIError
      Rails.logger.warn "Can't encode request_path '#{params[:base_path]}'"
      return head :bad_request
    rescue StandardError => e
      raise e unless Rails.env.development?

      handle_error_in_development(e)
    end
  end

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

      process_graphql_result(result)

      render json: result
    rescue StandardError => e
      raise e unless Rails.env.development?

      handle_error_in_development(e)
    end
  end

private

  def process_graphql_result(result)
    set_prometheus_labels(result.dig("data", "edition")&.slice("document_type", "schema_name"))

    if result.key?("errors")
      logger.warn("GraphQL query result contained errors: #{result['errors']}")
      set_prometheus_labels("contains_errors" => true)
    else
      logger.debug("GraphQL query result: #{result}")
      set_prometheus_labels("contains_errors" => false)
    end
  end

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

  # Constrain the cache time to be within the minimum_ttl and default_ttl.
  def bounded_max_age(cache_time)
    if cache_time > Rails.application.config.default_ttl
      Rails.application.config.default_ttl
    elsif cache_time < Rails.application.config.minimum_ttl
      Rails.application.config.minimum_ttl
    else
      cache_time
    end
  end

  def set_prometheus_labels(hash)
    return unless hash

    prometheus_labels = request.env.fetch("govuk.prometheus_labels", {})

    request.env["govuk.prometheus_labels"] = prometheus_labels.merge(hash)
  end

  def set_cache_headers
    # NOTE: this will need to support `max_cache_time` when schemas that have this field are available through GraphQL
    cache_time = Rails.application.config.default_ttl

    expires_in bounded_max_age(cache_time), public: true
  end

  def set_cors_headers
    # Allow any origin host to request the resource
    response.headers["Access-Control-Allow-Origin"] = "*"
  end
end
