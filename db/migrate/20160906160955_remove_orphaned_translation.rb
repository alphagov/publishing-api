class RemoveOrphanedTranslation < ActiveRecord::Migration
  def up
    #/guidance/equitable-life-payment-scheme.de
    #id: 23835, content_id: "5f5890da-7631-11e4-a3cb-005056011aef"
    #Whitehall - edition_id: 649963

    content_item = ContentItem.find_by_id(23835)
    if content_item
      Services::DeleteContentItem.destroy_supporting_objects([content_item])
      content_item.destroy
    end
  end
end
