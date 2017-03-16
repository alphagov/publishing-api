module V2
  class LinkSetsController < ApplicationController
    def get_links
      render json: Queries::GetLinkSet.call(content_id)
    end

    def expanded_links
      render json: Queries::GetExpandedLinks.call(
        content_id,
        params[:locale],
        with_drafts: with_drafts?,
      )
    end

    def patch_links
      response = Commands::V2::PatchLinkSet.call(links_params)
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

    def with_drafts?
      # Cast the `with_drafts` query param to a real boolean, and default to
      # `true` to preserve existing behaviour
      ActiveModel::Type::Boolean.new.cast(params.fetch(:with_drafts, true))
    end

    def links_params
      payload.merge(content_id: content_id)
    end

    def content_id
      params.fetch(:content_id)
    end
  end
end
