class DropPassthroughHashFromLinks < ActiveRecord::Migration
  def change
    remove_column :links, :passthrough_hash, :json
  end
end
