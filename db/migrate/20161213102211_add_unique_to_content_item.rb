class AddUniqueToContentItem < ActiveRecord::Migration[5.0]
  def up
    add_column :content_items, :content_store, :string
    execute "UPDATE content_items SET content_store = (
             SELECT CASE WHEN state = 'draft' THEN 'draft' WHEN state IN ('published', 'unpublished') THEN 'live' ELSE NULL END FROM content_items c
             WHERE c.id = content_items.id
             )"
    add_index :content_items, [:locale, :content_id, :content_store], unique: true
  end

  def down
  end
end

