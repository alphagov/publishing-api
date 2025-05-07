class RemoveLinkSetId < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :links, :link_set_id, :integer }
  end
end
