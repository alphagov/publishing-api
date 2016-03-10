class AddLastPublishedAtToContentItems < ActiveRecord::Migration
  def change
    add_column :content_items, :last_published_at, :datetime
  end
end
