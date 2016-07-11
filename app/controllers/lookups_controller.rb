class LookupsController < ApplicationController
  def by_base_path
    # return content_ids for content that is visible on the live site
    # withdrawn items are still visible
    states = params[:state] || %w(published unpublished)
    base_paths = params.fetch(:base_paths)

    base_paths_and_content_ids = ContentItemFilter
      .filter(state: states, base_path: base_paths)
      .pluck(:base_path, :content_id)
      .uniq

    response = Hash[base_paths_and_content_ids]
    render json: response
  end
end
