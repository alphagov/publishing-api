class AddRoutesIndexToEditions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :editions, :redirects, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
    add_index :editions, :routes, using: :gin, opclass: :jsonb_path_ops, algorithm: :concurrently
  end
end
