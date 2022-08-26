class AddIndexForCmsEntityIds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :editions, :cms_entity_ids, using: "gin", algorithm: :concurrently
  end
end
