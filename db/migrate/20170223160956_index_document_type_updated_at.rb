class IndexDocumentTypeUpdatedAt < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def change
    add_index :editions, %i[document_type updated_at], algorithm: :concurrently
    remove_index :editions, :document_type
  end
end
