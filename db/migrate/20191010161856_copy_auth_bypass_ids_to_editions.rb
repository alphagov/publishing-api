class CopyAuthBypassIdsToEditions < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    AccessLimit.includes(:edition).find_each do |access_limit|
      next unless access_limit.edition
      access_limit.edition.update_column(:auth_bypass_ids, access_limit.auth_bypass_ids)
    end
  end
end
