class AddPublisherTimestampsToEdition < ActiveRecord::Migration[5.1]
  def change
    add_column :editions, :publisher_first_published_at, :datetime
    add_column :editions, :publisher_major_published_at, :datetime
    add_column :editions, :publisher_minor_published_at, :datetime
    add_column :editions, :publisher_last_edited_at, :datetime
  end
end
