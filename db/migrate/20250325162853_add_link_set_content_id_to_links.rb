class AddLinkSetContentIdToLinks < ActiveRecord::Migration[8.0]
  def change
    add_column :links, :link_set_content_id, :uuid
    add_foreign_key :links, :link_sets, column: :link_set_content_id, primary_key: :content_id
  end
end
