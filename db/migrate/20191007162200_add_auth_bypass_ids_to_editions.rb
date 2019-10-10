class AddAuthBypassIdsToEditions < ActiveRecord::Migration[5.2]
  def change
    add_column :editions, :auth_bypass_ids, :string, array: true
  end
end
