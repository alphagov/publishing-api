class AddFirstPublishedAt < ActiveRecord::Migration[4.2]
  def change
    add_column :content_items, :first_published_at, :datetime
  end
end
