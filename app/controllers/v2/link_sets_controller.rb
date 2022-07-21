module V2
  class LinkSetsController < ApplicationController
    def get_links
      render json: Queries::GetLinkSet.call(content_id)
    end

    def bulk_links
      throw_payload_error if max_payload_size_exceeded?
      json = Queries::GetBulkLinks.call(content_ids)
      render json: json
    end

    def expanded_links
      json = Queries::GetExpandedLinks.call(
        content_id,
        locale,
        with_drafts: with_drafts?,
        generate: generate?,
      )

      render json: json
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

    def generate?
      ActiveModel::Type::Boolean.new.cast(params.fetch(:generate, false))
    end

    def throw_payload_error
      raise CommandError.new(
        code: 413,
        message: "Payload size exceeded 1000 ids",
      )
    end

    def max_payload_size_exceeded?
      content_ids.size > 1000
    end

    def content_ids
      params.fetch(:content_ids)
    end

    def links_params
      payload.merge(content_id: content_id)
    end

    def content_id
      params.fetch(:content_id)
    end

    def locale
      params.fetch(:locale, Edition::DEFAULT_LOCALE)
    end
  end
end
