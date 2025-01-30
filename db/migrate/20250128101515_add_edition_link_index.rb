class AddEditionLinkIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :links, %i[edition_id link_type], algorithm: :concurrently
  end
end
