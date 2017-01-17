require_relative "helpers/delete_content_item"

class January6RemoveConflictingContentItems < ActiveRecord::Migration[5.0]
  def up
    to_delete = [1624168, 1624157, 1622943]
    content_items = ContentItem.where(id: to_delete)
    Helpers::DeleteContentItem.destroy_supporting_objects(content_items)
    content_items.destroy_all
  end
end
