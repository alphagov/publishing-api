class AllowNullDraftContentId < ActiveRecord::Migration
  def change
    remove_foreign_key :live_content_items, :draft_content_item
    change_column_null :live_content_items, :draft_content_item_id, true
  end
end
