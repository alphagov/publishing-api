class LinkDocumentsAndEditions < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def change
    add_column :content_items, :document_id, :integer
    add_foreign_key :content_items, :documents

    add_index :content_items, [:document_id, :user_facing_version], unique: true, algorithm: :concurrently
    add_index :content_items, [:document_id, :content_store], unique: true, algorithm: :concurrently
    add_index :content_items, [:document_id, :state], algorithm: :concurrently
  end
end
