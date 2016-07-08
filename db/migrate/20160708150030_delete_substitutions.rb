class DeleteSubstitutions < ActiveRecord::Migration
  def up
    attributes = Unpublishing
      .where(type: "substitute")
      .joins(:content_item)
      .pluck(:content_item_id, :content_id)

    count = 0

    attributes.each do |(id, content_id)|
      supporting_classes = [
        AccessLimit,
        Linkable,
        Location,
        State,
        Translation,
        Unpublishing,
        UserFacingVersion
      ]

      supporting_classes.each do |klass|
        klass.where(content_item_id: id).destroy_all
      end

      LockVersion.where(target_id: id, target_type: "ContentItem").destroy_all

      ContentItem.where(id: id).destroy_all

      unless ContentItem.exists?(content_id: content_id)
        LinkSet.where(content_id: content_id).destroy_all
      end

      count += 1
    end

    puts "Deleted #{count} content items"
  end
end
