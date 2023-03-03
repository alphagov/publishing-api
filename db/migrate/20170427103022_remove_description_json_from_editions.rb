class RemoveDescriptionJSONFromEditions < ActiveRecord::Migration[5.0]
  def change
    remove_column :editions, :description_json
  end
end
