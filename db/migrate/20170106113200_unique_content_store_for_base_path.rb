class UniqueContentStoreForBasePath < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def change
    # No 2 content items with the same base_path can be on the same
    # content_store at same time
    add_index :content_items,
              %i[base_path content_store],
              unique: true,
              algorithm: :concurrently
  end
end
