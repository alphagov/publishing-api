class RemoveAccessLimitedColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column :draft_content_items, :access_limited, :json, default: {}
  end
end
