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
        {
          title: edition.title,
          base_path: edition.base_path,
          document_type: edition.document_type,
          publishing_app: edition.publishing_app,
          last_edited_by_editor_id: edition.last_edited_by_editor_id,
          last_edited_at: edition.last_edited_at,
          unique_pageviews: edition.unique_pageviews,
          instances: edition.instances,
          host_content_id: edition.host_content_id,
          primary_publishing_organisation: {
            content_id: edition.primary_publishing_organisation_content_id,
            title: edition.primary_publishing_organisation_title,
            base_path: edition.primary_publishing_organisation_base_path,
          },
        }
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