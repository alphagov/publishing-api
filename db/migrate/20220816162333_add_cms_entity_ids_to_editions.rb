class AddCmsEntityIdsToEditions < ActiveRecord::Migration[7.0]
  def change
    add_column :editions, :cms_entity_ids, :text, array: true, null: false, default: []
  end
end
