class AddIndexToEditionIdAndContentStore < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :editions, %i[id content_store], algorithm: :concurrently
  end
end
