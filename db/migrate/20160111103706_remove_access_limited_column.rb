class RemoveAccessLimitedColumn < ActiveRecord::Migration
  def change
    remove_column :draft_content_items, :access_limited, :json, default: {}
  end
end
