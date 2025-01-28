class AddEditionLinkIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :links, %i[edition_id link_type]
  end
end
