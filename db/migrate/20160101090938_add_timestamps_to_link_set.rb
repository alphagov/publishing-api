class AddTimestampsToLinkSet < ActiveRecord::Migration
  def up
    add_timestamps :link_sets
  end

  def down
    remove_timestamps :link_sets
  end
end
