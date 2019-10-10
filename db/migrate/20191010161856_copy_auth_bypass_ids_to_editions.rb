class CopyAuthBypassIdsToEditions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    AccessLimit.includes(:edition).find_each do |access_limit|
      access_limit.edition.update!(auth_bypass_ids: access_limit.auth_bypass_ids)
    end
  end
end
