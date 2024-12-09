module Presenters
  class HostContentPresenter
    def self.present(target_edition_id, host_content, total, total_pages, rollup)
      new(target_edition_id, host_content, total, total_pages, rollup).present
    end

    def initialize(target_edition_id, host_content, total, total_pages, rollup)
      @target_edition_id = target_edition_id
      @host_content = host_content.to_a
      @total = total
      @total_pages = total_pages
      @rollup = rollup
    end

    def present
      {
        content_id: target_edition_id,
        total:,
        total_pages:,
        rollup:,
        results:,
      }
    end

    def results
      return [] unless host_content.any?

      host_content.map do |edition|
        HostContentItemPresenter.present(edition)
      end
    end

  private

    def rollup
      {
        views: @rollup.views,
        locations: @rollup.locations,
        instances: @rollup.instances,
        organisations: @rollup.organisations,
      }.transform_values(&:to_i)
    end

    attr_reader :target_edition_id, :host_content, :total, :total_pages
  end
end
