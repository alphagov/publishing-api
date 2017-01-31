class RemoveContentIdAndLocaleFieldsFromEdition < ActiveRecord::Migration[5.0]
  def up
    remove_column :editions, :content_id
    remove_column :editions, :locale
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
