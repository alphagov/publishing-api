class RenameDescriptionAndDescriptionString < ActiveRecord::Migration[5.0]
  def change
    rename_column :editions, :description, :description_json
    rename_column :editions, :description_string, :description
  end
end
