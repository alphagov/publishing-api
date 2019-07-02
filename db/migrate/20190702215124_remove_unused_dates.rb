class RemoveUnusedDates < ActiveRecord::Migration[5.2]
  def change
    change_table :editions, bulk: true do |t|
      t.remove :publisher_first_published_at
      t.remove :publisher_major_published_at
      t.remove :publisher_published_at
      t.remove :publisher_last_edited_at
    end
  end
end
