require_relative "helpers/delete_content_item"

class January6RemoveConflictingContentItems2 < ActiveRecord::Migration[5.0]
  def up
    to_delete = [1624998, 1624938, 1624972]
    content_items = ContentItem.where(id: to_delete)
    Helpers::DeleteContentItem.destroy_supporting_objects(content_items)
    content_items.destroy_all
  end
end
