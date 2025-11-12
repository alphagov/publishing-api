# frozen_string_literal: true

class GraphqlController < ApplicationController
  # If accessing from outside this domain, nullify the session
  # This allows for outside API access while preventing CSRF attacks,
  # but you'll have to authenticate your user separately
  # protect_from_forgery with: :null_session

  skip_before_action :authenticate_user!, only: %i[execute live_content]

  DEFAULT_TTL = ENV.fetch("DEFAULT_TTL", 5.minutes).to_i.seconds
  MINIMUM_TTL = [DEFAULT_TTL, 5.seconds].min

  def live_content
    execute_in_read_replica do
      begin
        set_cache_headers

        encoded_base_path = Addressable::URI.encode("/#{params[:base_path]}")
        edition = EditionFinderService.new(encoded_base_path, "live").find
        return head :not_found unless edition

        if edition.base_path != encoded_base_path
          return redirect_to graphql_live_content_path(base_path: edition.base_path.gsub(/^\//, "")), status: :see_other
        end

        begin
          query = File.read(Rails.root.join("app/graphql/queries/#{edition.schema_name}.graphql"))
        rescue Errno::ENOENT
          return head :not_found
        end

        result = PublishingApiSchema.execute(query, variables: { base_path: encoded_base_path }).to_hash
        report_result(result)

        content_item = GraphqlContentItemService.for_edition(edition).process(result)

        http_status = if content_item["schema_name"] == "gone" && (content_item["details"].nil? || content_item["details"].values.reject(&:blank?).empty?)
                        410
                      else
                        200
                      end

        render json: content_item, status: http_status
      end
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

      report_result(result)

      render json: result
    rescue StandardError => e
      raise e unless Rails.env.development?

      handle_error_in_development(e)
    end
  end

private

  def report_result(result)
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
    if cache_time > DEFAULT_TTL
      DEFAULT_TTL
    elsif cache_time < MINIMUM_TTL
      MINIMUM_TTL
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
    cache_time = DEFAULT_TTL

    expires_in bounded_max_age(cache_time), public: true
  end
end
