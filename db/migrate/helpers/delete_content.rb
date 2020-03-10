module Helpers
  module DeleteContent
    def self.destroy_documents_with_links(content_ids)
      content_ids = Array(content_ids)

      Document.where(content_id: content_ids).each do |document|
        destroy_edition_supporting_objects(document.editions)
        document.editions.destroy_all
        document.destroy
      end

      destroy_links(content_ids)
    end

    def self.destroy_edition_supporting_objects(editions)
      editions = Array(editions)

      supporting_classes = [
        AccessLimit,
        Unpublishing,
        ChangeNote,
      ]

      supporting_classes.each do |klass|
        next unless ActiveRecord::Base.connection.data_source_exists?(klass.table_name)

        klass.where(edition: editions).destroy_all
      end
    end

    def self.destroy_links(content_ids)
      content_ids = Array(content_ids)
      LinkSet.where(content_id: content_ids).destroy_all
      Link.where(target_content_id: content_ids).destroy_all
    end
  end
end
