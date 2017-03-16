class AddAuthBypassId < ActiveRecord::Migration[5.0]
  def change
    add_column :access_limits, :auth_bypass_ids, :json, null: false, default: []
  end
end
