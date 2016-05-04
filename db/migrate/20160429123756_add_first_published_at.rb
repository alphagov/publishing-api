class AddFirstPublishedAt < ActiveRecord::Migration
  def change
    add_column :content_items, :first_published_at, :datetime
  end
end
