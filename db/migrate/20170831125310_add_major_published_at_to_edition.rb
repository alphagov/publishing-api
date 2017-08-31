class AddMajorPublishedAtToEdition < ActiveRecord::Migration[5.1]
  def change
    add_column :editions, :major_published_at, :datetime
  end
end
