module V2
  #
  # This controller provides endpoints for querying content and links together.
  #
  class GroupedContentAndLinksController < ApplicationController
    #
    # Query all content items and links. This can be used to extract data for
    # batch processing tasks.
    #
    # Results are grouped by content id and are paginated using the
    # last_seen_content_id parameter.
    #
    def index
      query = Queries::GetGroupedContentAndLinks.new(
        last_seen_content_id: params[:last_seen_content_id],
        page_size: params[:page_size],
      )

      if query.valid?
        render json: Presenters::Queries::GroupedContentAndLinks.new(query.call).present
      else
        render json: { errors: query.errors.full_messages }, status: 422
      end
    end
  end
end
