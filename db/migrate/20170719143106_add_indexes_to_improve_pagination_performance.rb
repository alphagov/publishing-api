class AddIndexesToImprovePaginationPerformance < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :editions, [:updated_at, :id], algorithm: :concurrently
    add_index :editions, [:created_at, :id], algorithm: :concurrently
    add_index :editions, [:public_updated_at, :id], algorithm: :concurrently
  end
end
