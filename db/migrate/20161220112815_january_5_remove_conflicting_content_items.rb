require_relative "helpers/delete_content_item"

class January5RemoveConflictingContentItems < ActiveRecord::Migration[5.0]
  def up
    content_items = ContentItem.where(id: 1377851)
    Helpers::DeleteContentItem.destroy_supporting_objects(content_items)
    content_items.destroy_all
  end
end
