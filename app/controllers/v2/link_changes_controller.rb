module V2
  class LinkChangesController < ApplicationController
    def index
      render json: Queries::GetLinkChanges.new(params, request.original_url).as_json
    end
  end
end
