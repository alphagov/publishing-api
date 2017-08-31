class RenameTemporaryPublishedAtToPublishedAt < ActiveRecord::Migration[5.1]
  def change
    rename_column :editions, :temporary_published_at, :published_at
  end
end
