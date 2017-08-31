class RenameTemporaryMajorPublishedAtToMajorPublishedAt < ActiveRecord::Migration[5.1]
  def change
    rename_column :editions, :temporary_major_published_at, :major_published_at
  end
end
