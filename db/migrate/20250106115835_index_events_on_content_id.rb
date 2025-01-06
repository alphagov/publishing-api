class IndexEventsOnContentId < ActiveRecord::Migration[7.2]
  def change
    add_index :events, :content_id
  end
end
