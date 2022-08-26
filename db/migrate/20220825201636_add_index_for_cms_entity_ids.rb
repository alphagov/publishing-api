class AddIndexForCmsEntityIds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    enable_extension :btree_gin
    add_index :editions, %i[cms_entity_ids updated_at id], using: "gin", where: "state in ('draft', 'published', 'unpublished')", algorithm: :concurrently, name: "cms_entity_ids_for_editions_idx"
  end
end
