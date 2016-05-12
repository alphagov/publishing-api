class IndexContentItemsOnUpdatedAt < ActiveRecord::Migration
  def change
    add_index :content_items, :updated_at
  end
end
