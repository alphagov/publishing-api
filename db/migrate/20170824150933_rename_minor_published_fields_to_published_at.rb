class RenameMinorPublishedFieldsToPublishedAt < ActiveRecord::Migration[5.1]
  def change
    rename_column :editions, :temporary_minor_published_at, :temporary_published_at
    rename_column :editions, :publisher_minor_published_at, :publisher_published_at
  end
end
