class AddPassthroughFieldToLink < ActiveRecord::Migration
  def change
    add_column :links, :passthrough_hash, :json
    change_column_null :links, :target_content_id, true
  end
end
