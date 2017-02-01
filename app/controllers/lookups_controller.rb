class LookupsController < ApplicationController
  def by_base_path
    # return content_ids for content that is visible on the live site
    # withdrawn items are still visible
    states = %w(published unpublished)
    base_paths = params.fetch(:base_paths)

    base_paths_and_content_ids = Edition.with_document
      .left_outer_joins(:unpublishing)
      .where(state: states, base_path: base_paths)
      .where("state = 'published' OR unpublishings.type = 'withdrawal'")
      .where("document_type NOT IN ('gone', 'redirect')")
      .pluck(:base_path, 'documents.content_id')
      .uniq

    response = Hash[base_paths_and_content_ids]
    render json: response
  end
end
