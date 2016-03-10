class LookupsController < ApplicationController
  def by_base_path
    base_paths_and_content_ids = ContentItemFilter
      .filter(state: "published", base_path: params.fetch(:base_paths))
      .pluck(:base_path, :content_id)
      .uniq

    response = Hash[base_paths_and_content_ids]
    render json: response
  end
end
