class LookupsController < ApplicationController
  def by_base_path
    # Return content ids of the documents accessible at the provided base paths.
    # Draft, published, or withdrawn content may be returned, but not anything
    # that is redirected or gone.
    # If there are multiple editions with the base path, prefer the published
    # one.
    base_paths = params.fetch(:base_paths)

    base_paths_and_content_ids = Edition.with_document
      .left_outer_joins(:unpublishing)
      .left_outer_joins(:access_limit)
      .where(base_path: base_paths)
      .where("access_limits.edition_id IS NULL")
      .where("state IN ('published', 'draft') OR (state = 'unpublished' AND unpublishings.type = 'withdrawal')")
      .where("document_type NOT IN ('gone', 'redirect')")
      .order(:base_path)
      .order("CASE editions.state WHEN 'published' THEN 0 WHEN 'unpublished' THEN 1 ELSE 2 END")
      .pluck("DISTINCT ON (editions.base_path) editions.base_path, documents.content_id")

    response = Hash[base_paths_and_content_ids]
    render json: response
  end
end
