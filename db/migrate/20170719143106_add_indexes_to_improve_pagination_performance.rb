class AddIndexesToImprovePaginationPerformance < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :editions, %i[updated_at id], algorithm: :concurrently
    add_index :editions, %i[created_at id], algorithm: :concurrently
    add_index :editions, %i[public_updated_at id], algorithm: :concurrently
  end
end
