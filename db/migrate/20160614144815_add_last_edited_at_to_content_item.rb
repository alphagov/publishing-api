class AddLastEditedAtToContentItem < ActiveRecord::Migration
  def change
    add_column :content_items, :last_edited_at, :datetime
    add_index :content_items, :last_edited_at
  end
end
