class IndexLinkChangesColumns < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :link_changes, %w[link_type], algorithm: :concurrently
    add_index :link_changes, %w[source_content_id], algorithm: :concurrently
    add_index :link_changes, %w[target_content_id], algorithm: :concurrently
  end
end
