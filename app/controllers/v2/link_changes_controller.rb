module V2
  class LinkChangesController < ApplicationController
    def index
      render json: Queries::GetLinkChanges.new(params).as_json
    end
  end
end
