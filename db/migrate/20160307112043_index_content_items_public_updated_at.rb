class IndexContentItemsPublicUpdatedAt < ActiveRecord::Migration
  def change
    add_index :content_items, :public_updated_at
  end
end
