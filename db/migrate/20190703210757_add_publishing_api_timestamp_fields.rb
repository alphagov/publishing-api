class AddPublishingApiTimestampFields < ActiveRecord::Migration[5.2]
  def change
    change_table :editions, bulk: true do |t|
      t.datetime :publishing_api_first_published_at
      t.datetime :publishing_api_last_edited_at
    end
  end
end
