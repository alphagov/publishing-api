require_relative "helpers/delete_content_item"

class RemoveContentItemWithSelfRedirect < ActiveRecord::Migration
  def up
    content_item = ContentItem.find_by_id(645143)

    if content_item
      Helpers::DeleteContentItem.destroy_supporting_objects(content_item)
      content_item.destroy
    end
  end
end
