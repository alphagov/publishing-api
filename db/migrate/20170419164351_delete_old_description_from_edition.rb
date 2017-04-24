class DeleteOldDescriptionFromEdition < ActiveRecord::Migration[5.0]
  def change
    remove_column :editions, :old_description
  end
end
