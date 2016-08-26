module Helpers
  module DeleteContentItem
    def self.destroy_supporting_objects(content_items)
      content_items = Array(content_items)

      supporting_classes = [
        AccessLimit,
        Linkable,
        Location,
        State,
        Translation,
        Unpublishing,
        UserFacingVersion,
      ]

      supporting_classes.each do |klass|
        klass.where(content_item: content_items).destroy_all
      end

      LockVersion.where(target: content_items).destroy_all
    end
  end
end
