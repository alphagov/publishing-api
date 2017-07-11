class AddIndexOnEditionState < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :editions, :state, algorithm: :concurrently
  end
end
