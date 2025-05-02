class RemoveIndexesFromLinks < ActiveRecord::Migration[8.0]
  def change
    remove_index :links, name: "index_links_on_link_set_id"
    remove_index :links, name: "index_links_on_link_set_id_and_target_content_id"
    remove_index :links, name: "index_links_on_link_set_id_and_link_type"
  end
end
