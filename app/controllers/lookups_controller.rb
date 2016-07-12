class LookupsController < ApplicationController
  # return content_ids for content that is visible on the live site
  # withdrawn items are still visible
  DEFAULT_STATES_FILTER = %w(published unpublished).freeze

  def by_base_path
    states = params[:state] ? valid_state_params : DEFAULT_STATES_FILTER

    base_paths = params.fetch(:base_paths)

    base_paths_and_content_ids = ContentItemFilter
      .filter(state: states, base_path: base_paths)
      .pluck(:base_path, :content_id)
      .uniq

    response = Hash[base_paths_and_content_ids]
    render json: response
  end

private

  def valid_state_params
    unless State.allowed_values.include?(params[:state])
      raise CommandError.new(
        code: 422,
        message: "state: '#{params[:state]}' not one of #{State.allowed_values}"
      )
    end
    params[:state]
  end
end
