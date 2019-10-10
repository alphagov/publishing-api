class AddNoneNullConstraintToAuthBypassIds < ActiveRecord::Migration[5.2]
  def change
    change_column_null :editions, :auth_bypass_ids, false
  end
end
