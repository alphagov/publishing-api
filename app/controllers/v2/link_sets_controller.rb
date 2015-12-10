module V2
  class LinkSetsController < ApplicationController

    rescue_from ActionController::ParameterMissing, with: :parameter_missing_error

    def get_links
      render json: Queries::GetLinkSet.call(content_id)
    end

    def put_links
      response = with_event_logging(Commands::V2::PutLinkSet, links_params) do
        Commands::V2::PutLinkSet.call(links_params)
      end

      render status: response.code, json: response
    end

    def get_linked
      render json: Queries::GetLinked.new(
        content_id: content_id,
        link_type: params.fetch(:link_type),
        fields: params.fetch(:fields),
      ).call
    end

  private
    def links_params
      payload.merge(content_id: content_id)
    end

    def content_id
      params.fetch(:content_id)
    end

    def parameter_missing_error(e)
      error = CommandError.new(code: 422, error_details: {
        error: {
          code: 422,
          message: e.message
        }
      })

      respond_with_command_error(error)
    end
  end
end
