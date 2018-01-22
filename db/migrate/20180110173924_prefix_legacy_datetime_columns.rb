class PrefixLegacyDatetimeColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :editions, :first_published_at, :legacy_first_published_at
    rename_column :editions, :public_updated_at, :legacy_public_updated_at
    rename_column :editions, :last_edited_at, :legacy_last_edited_at
  end
end
