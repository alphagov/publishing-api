class AddLinkSetContentIdIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :links, [:link_set_content_id], algorithm: :concurrently
    add_index :links, %i[link_set_content_id link_type], algorithm: :concurrently
    add_index :links, %i[link_set_content_id target_content_id], algorithm: :concurrently
  end
end
