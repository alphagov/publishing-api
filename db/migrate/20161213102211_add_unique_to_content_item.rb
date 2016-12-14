class AddUniqueToContentItem < ActiveRecord::Migration[5.0]
  def change
    add_column :content_items, :content_store, :string
    add_index :content_items, [:content_id, :locale, :content_store], unique: true
  end
end
