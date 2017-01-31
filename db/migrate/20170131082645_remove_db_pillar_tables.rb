class RemoveDbPillarTables < ActiveRecord::Migration[5.0]
  def up
    drop_table :locations
    drop_table :states
    drop_table :translations
    drop_table :user_facing_versions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
