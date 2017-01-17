require_relative "helpers/delete_content_item"

class RemoveInvalidDraftContentItem < ActiveRecord::Migration[5.0]
  def up
    id = 1238944
    content_item = ContentItem.find_by(id: id)
    if content_item
      Helpers::DeleteContentItem.destroy_supporting_objects(content_item)
      content_item.destroy
    end
  end

  def down
  end
end
