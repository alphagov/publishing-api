module Services
  class DeleteContentItem
    def self.destroy_content_items_with_links(content_ids)
      content_ids = Array(content_ids)

      content_items = ContentItem.where(content_id: content_ids)
      destroy_supporting_objects(content_items)
      content_items.destroy_all

      destroy_links(content_ids)
    end

    def self.destroy_supporting_objects(content_items)
      content_items = Array(content_items)

      supporting_classes = [
        AccessLimit,
        Location,
        State,
        Translation,
        Unpublishing,
        UserFacingVersion,
        ChangeNote,
      ]

      supporting_classes.each do |klass|
        next unless ActiveRecord::Base.connection.data_source_exists?(klass.table_name)
        klass.where(content_item: content_items).destroy_all
      end

      LockVersion.where(target: content_items).destroy_all
    end

    def self.destroy_links(content_ids)
      content_ids = Array(content_ids)
      LinkSet.where(content_id: content_ids).destroy_all
      Link.where(target_content_id: content_ids).destroy_all
    end
  end
end
