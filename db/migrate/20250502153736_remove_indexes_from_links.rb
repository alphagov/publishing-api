class RemoveIndexesFromLinks < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    remove_index :links, column: [:link_set_id], name: "index_links_on_link_set_id", algorithm: :concurrently
    remove_index :links, column: %i[link_set_id target_content_id], name: "index_links_on_link_set_id_and_target_content_id", algorithm: :concurrently
    remove_index :links, column: %i[link_set_id link_type], name: "index_links_on_link_set_id_and_link_type", algorithm: :concurrently
  end
end
