class AddAuthBypassIdsToEditions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :editions, :auth_bypass_ids, :string, array: true, null: false, default: []
  end
end
