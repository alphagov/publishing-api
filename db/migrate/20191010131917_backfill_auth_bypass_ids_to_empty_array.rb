class BackfillAuthBypassIdsToEmptyArray < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    Edition.in_batches(of: 5000).each_with_index do |batch, index|
      batch.update_all(auth_bypass_ids: [])
      puts "Updated #{(index + 1) * 5000} auth_bypass_ids"
    end
  end

  def down
    Edition.in_batches(of: 5000) do |batch|
      batch.update_all(auth_bypass_ids: nil)
    end
  end
end
