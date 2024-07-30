module Presenters
  module Queries
    # TODO: Naming of this so it fits consistently along side all the other presenters with 'link' in it
    class LinkedContentItemsPresenter
      def self.present(editions)
        new(editions).present
      end

      def initialize(editions)
        self.editions = editions
      end

      def present
        {
          linked_content_items:,
        }
      end

      def linked_content_items
        return {} unless editions.any?

        editions.map do |edition|
          {
            title: edition.title,
            base_path: edition.base_path,
            document_type: edition.document_type,
            publishing_organisation: publishing_organisation(edition),
          }
        end
      end

    private

      attr_accessor :editions

      def publishing_organisation(edition)
        # TODO: Remember to hande missing publishing links. I managed to create a document without a publishing organisation locally
        # TODO: Explore making a new association to get this association more simply and efficiently
        publishing_organisation_content_id = edition.primary_publishing_organisation_link&.target_content_id
        organisation_edition = Document.find_by_content_id(publishing_organisation_content_id)&.live
        return {} unless organisation_edition

        {
          title: organisation_edition&.title,
          base_path: organisation_edition&.base_path,
        }
      end
    end
  end
end
