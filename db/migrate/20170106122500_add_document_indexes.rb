class AddDocumentIndexes < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def change
    add_index :content_items, :document_id, algorithm: :concurrently
    add_index :content_items, %i[document_id user_facing_version], unique: true, algorithm: :concurrently
    add_index :content_items, %i[document_id content_store], unique: true, algorithm: :concurrently
    add_index :content_items, %i[document_id state], algorithm: :concurrently
  end
end
