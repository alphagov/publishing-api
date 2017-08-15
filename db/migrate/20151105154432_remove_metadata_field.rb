class RemoveMetadataField < ActiveRecord::Migration[4.2]
  def change
    remove_column :live_content_items, :metadata
    remove_column :draft_content_items, :metadata
  end
end
