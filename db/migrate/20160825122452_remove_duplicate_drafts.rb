class RemoveDuplicateDrafts < ActiveRecord::Migration
  def up
    content_items = ContentItem.where(id: [815434, 818621])

    if content_items.any? { |x| x.updated_at != x.created_at }
      raise "content item #{x.id} has been changed"
    end

    states = State.where(content_item: content_items)

    if states.any? { |x| x.name != "draft" }
      raise "content item #{x.id} not in draft state"
    end

    states.destroy_all

    other_supporting_classes = [
      AccessLimit,
      Linkable,
      Location,
      Translation,
      Unpublishing,
      UserFacingVersion
    ]

    other_supporting_classes.each do |klass|
      klass.where(content_item: content_items).destroy_all
    end

    LockVersion.where(target: content_items).destroy_all

    content_items.destroy_all
  end
end
