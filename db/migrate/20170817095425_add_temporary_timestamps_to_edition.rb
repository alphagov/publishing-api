class AddTemporaryTimestampsToEdition < ActiveRecord::Migration[5.1]
  def change
    add_column :editions, :temporary_first_published_at, :datetime
    add_column :editions, :temporary_major_published_at, :datetime
    add_column :editions, :temporary_minor_published_at, :datetime
    add_column :editions, :temporary_last_edited_at, :datetime
  end
end
