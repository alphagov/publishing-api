class AddIndexesForLinkables < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  def change
    add_index :editions, [:document_type, :state], algorithm: :concurrently
    add_index :documents, [:id, :locale], algorithm: :concurrently
  end
end
