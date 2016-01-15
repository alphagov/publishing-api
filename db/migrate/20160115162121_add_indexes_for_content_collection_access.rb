class AddIndexesForContentCollectionAccess < ActiveRecord::Migration
  def change
      add_index :draft_content_items, :format
      add_index :live_content_items, :format
      add_index :versions, :target_id
  end
end
