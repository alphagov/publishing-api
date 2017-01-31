class RenameContentItemsToEditions < ActiveRecord::Migration[5.0]
  def change
    rename_table :content_items, :editions

    rename_column :access_limits, :content_item_id, :edition_id
    rename_column :actions, :content_item_id, :edition_id
    rename_column :change_notes, :content_item_id, :edition_id
    rename_column :unpublishings, :content_item_id, :edition_id
  end
end
