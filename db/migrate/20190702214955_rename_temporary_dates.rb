class RenameTemporaryDates < ActiveRecord::Migration[5.2]
  def change
    change_table :editions, bulk: true do |t|
      t.rename :temporary_first_published_at, :publishing_api_first_published_at
      t.rename :temporary_last_edited_at, :publishing_api_last_edited_at
    end
  end
end
