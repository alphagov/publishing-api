class RemoveInvalidDraftContentItem < ActiveRecord::Migration[5.0]
  def up
    id = 1238944
    content_item = ContentItem.find_by(id: id)
    if content_item
      Services::DeleteContentItem.destroy_supporting_objects(content_item)
      content_item.destroy
    end
  end

  def down
  end
end
