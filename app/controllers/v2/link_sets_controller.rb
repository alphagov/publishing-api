module V2
  class LinkSetsController < ApplicationController
    def get_links
      render json: Queries::GetLinkSet.call(params[:content_id])
    end
  end
end
