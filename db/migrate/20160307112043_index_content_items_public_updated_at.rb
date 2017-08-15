class IndexContentItemsPublicUpdatedAt < ActiveRecord::Migration[4.2]
  def change
    add_index :content_items, :public_updated_at
  end
end
