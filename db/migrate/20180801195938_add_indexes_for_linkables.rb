class AddIndexesForLinkables < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  def change
    add_index :editions, %i[document_type state], algorithm: :concurrently
    add_index :documents, %i[id locale], algorithm: :concurrently
  end
end
