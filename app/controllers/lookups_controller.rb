class LookupsController < ApplicationController
  def by_base_path
    base_paths = params.fetch(:base_paths)

    if with_drafts
      states = %w(draft published unpublished)
      content_stores = %w(draft live)
    else
      # return content_ids for content that is visible on the live site
      # withdrawn items are still visible
      states = %w(published unpublished)
      content_stores = 'live'
    end

    scope = Edition.left_outer_joins(:unpublishing)

    # where not in (..) does not return records that where the field is null
    scope = scope.where(unpublishings: { type: nil }).or(
      scope.where.not(unpublishings: { type: params.fetch(:exclude_unpublishing_types, %w{vanish redirect gone}) })
    )

    scope = scope.with_document
      .where(state: states, content_store: content_stores, base_path: base_paths)
      .where.not(document_type: params.fetch('exclude_document_types', %w{gone redirect}))
      .order(state: :desc)

    base_paths_and_content_ids = scope.pluck(
      Arel.sql("distinct on (editions.base_path, editions.state) editions.base_path, documents.content_id")
    )

    response = Hash[base_paths_and_content_ids]
    render json: response
  end

private

  def with_drafts
    ActiveModel::Type::Boolean.new.cast(params.fetch(:with_drafts, false))
  end
end
