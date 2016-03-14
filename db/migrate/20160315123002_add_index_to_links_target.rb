class AddIndexToLinksTarget < ActiveRecord::Migration
  def change
    add_index :links, :target_content_id
    add_index :links, [:target_content_id, :link_type]
  end
end
