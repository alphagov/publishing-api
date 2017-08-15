class IndexContentItemsOnUpdatedAt < ActiveRecord::Migration[4.2]
  def change
    add_index :content_items, :updated_at
  end
end
