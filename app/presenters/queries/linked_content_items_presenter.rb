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
          }
        end
      end

    private

      attr_accessor :editions

    end
  end
end
