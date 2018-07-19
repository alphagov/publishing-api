class DropNeedIdsFromEditions < ActiveRecord::Migration[5.1]
  def change
    remove_column :editions, :need_ids
  end
end
