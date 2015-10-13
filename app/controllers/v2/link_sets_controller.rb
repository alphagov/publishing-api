module V2
  class LinkSetsController < ApplicationController
    def get_links
      render json: Queries::GetLinkSet.call(content_id)
    end

    def put_links
      response = with_event_logging(Commands::V2::PutLinkSet, links_params) do
        Commands::V2::PutLinkSet.call(links_params)
      end

      render status: response.code, json: response
    end

  private
    def links_params
      payload.merge(content_id: content_id)
    end

    def content_id
      params.fetch(:content_id)
    end
  end
end
