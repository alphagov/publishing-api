class AddIndexToLinksTarget < ActiveRecord::Migration[4.2]
  def change
    add_index :links, :target_content_id
    add_index :links, %i[target_content_id link_type]
  end
end
