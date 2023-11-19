class AddIndexToLinkChanges < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  def change
    add_index :link_changes, %w[created_at], name: "index_link_changes_on_created_at", order: { created_at: :desc }, algorithm: :concurrently
  end
end
