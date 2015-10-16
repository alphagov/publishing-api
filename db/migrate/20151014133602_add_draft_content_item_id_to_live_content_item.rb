class AddDraftContentItemIdToLiveContentItem < ActiveRecord::Migration
  class DraftContentItem < ActiveRecord::Base
  end

  class LiveContentItem < ActiveRecord::Base
    belongs_to :draft_content_item
  end

  def change
    add_reference :live_content_items, :draft_content_item, index: true

    LiveContentItem.all.each do |live_item|
      draft_item = DraftContentItem.find_by(content_id: live_item.content_id)

      live_item.draft_content_item = draft_item
      live_item.save!
    end

    change_column_null :live_content_items, :draft_content_item_id, false
  end
end
