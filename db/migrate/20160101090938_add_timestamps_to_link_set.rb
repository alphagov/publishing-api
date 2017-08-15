class AddTimestampsToLinkSet < ActiveRecord::Migration[4.2]
  def up
    add_timestamps :link_sets
  end

  def down
    remove_timestamps :link_sets
  end
end
