class RemoveLockVersionTable < ActiveRecord::Migration[5.0]
  def up
    drop_table :lock_versions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
