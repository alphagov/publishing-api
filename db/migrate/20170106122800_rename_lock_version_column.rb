class RenameLockVersionColumn < ActiveRecord::Migration[5.0]
  def up
    rename_column :documents, :lock_version, :stale_lock_version
    rename_column :link_sets, :lock_version, :stale_lock_version
  end

  def down
    rename_column :documents, :stale_lock_version, :lock_version
    rename_column :link_sets, :stale_lock_version, :lock_version
  end
end
