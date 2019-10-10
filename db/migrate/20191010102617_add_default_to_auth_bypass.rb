class AddDefaultToAuthBypass < ActiveRecord::Migration[5.2]
  def change
    change_column_default :editions, :auth_bypass_ids, []
  end
end
