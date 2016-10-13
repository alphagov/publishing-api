class RemoveLinkables < ActiveRecord::Migration[5.0]
  def change
    drop_table :linkables
  end
end
