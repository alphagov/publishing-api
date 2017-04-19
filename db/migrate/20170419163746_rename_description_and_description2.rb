class RenameDescriptionAndDescription2 < ActiveRecord::Migration[5.0]
  def change
    rename_column :editions, :description, :old_description
    rename_column :editions, :description2, :description
  end
end
