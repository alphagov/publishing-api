class RemoveAuthBypassIdsFromAccessLimits < ActiveRecord::Migration[5.2]
  def change
    remove_column :access_limits, :auth_bypass_ids, :json
  end
end
