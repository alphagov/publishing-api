class DropOldTables < ActiveRecord::Migration
  def change
    drop_table :draft_content_items
    drop_table :live_content_items
    drop_table :versions

    remove_column :content_items, :draft_content_item_id
    remove_column :content_items, :live_content_item_id
    remove_column :content_items, :access_limited
    remove_column :access_limits, :target_id
    remove_column :access_limits, :target_type
  end
end
