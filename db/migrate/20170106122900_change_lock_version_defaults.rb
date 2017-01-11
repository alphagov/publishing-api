class ChangeLockVersionDefaults < ActiveRecord::Migration[5.0]
  def up
    change_column_default :link_sets, :stale_lock_version, 0
    change_column_default :documents, :stale_lock_version, 0
  end

  def down
    change_column_default :link_sets, :stale_lock_version, 1
    change_column_default :documents, :stale_lock_version, 1
  end
end
