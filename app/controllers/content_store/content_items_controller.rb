class ContentStore::ContentItemsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @edition = find_content_item(content_store: params[:content_store], path: base_path)
    raise_error(404, "Could not find a content item for #{base_path}") unless @edition
    # NOTE: version here is @edition.user_facing_version, not Event.maximum(:id)
    # as that is only for managing conflicts between publishing-api and content-store
    #
    @content_item = DownstreamPayload.new(@edition, @edition.user_facing_version, draft: draft?)
    render json: @content_item.content_store_payload
  end

private

  def find_content_item(content_store:, path:)
    FindByPath.new(Edition.where(content_store:)).find(path)
  end

  def draft?
    params[:content_store] == "draft"
  end

  def raise_error(code, message)
    raise CommandError.new(
      code:,
      error_details: {
        error: {
          code:,
          message:,
        },
      },
    )
  end
end
