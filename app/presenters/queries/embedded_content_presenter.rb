module Presenters
  module Queries
    class EmbeddedContentPresenter
      def self.present(target_edition_id, host_editions)
        new(target_edition_id, host_editions).present
      end

      def initialize(target_edition_id, host_editions)
        self.target_edition_id = target_edition_id
        self.host_editions = host_editions.to_a
      end

      def present
        {
          content_id: target_edition_id,
          total: host_editions.count,
          results:,
        }
      end

      def results
        return [] unless host_editions.any?

        host_editions.map do |edition|
          {
            title: edition.title,
            base_path: edition.base_path,
            document_type: edition.document_type,
            publishing_app: edition.publishing_app,
            last_edited_by_editor_id: edition.last_edited_by_editor_id,
            last_edited_at: edition.last_edited_at,
            primary_publishing_organisation: {
              content_id: edition.primary_publishing_organisation_content_id,
              title: edition.primary_publishing_organisation_title,
              base_path: edition.primary_publishing_organisation_base_path,
            },
          }
        end
      end

    private

      attr_accessor :target_edition_id, :host_editions
    end
  end
end
