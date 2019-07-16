class DropExtraDateFields < ActiveRecord::Migration[5.2]
  def change
    change_table :editions, bulk: true do |t|
      t.remove :publisher_first_published_at,
               :publisher_last_edited_at,
               :publisher_major_published_at,
               :publisher_published_at,
               :temporary_first_published_at,
               :temporary_last_edited_at
    end
  end
end
