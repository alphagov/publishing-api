class RemoveVersionFields < ActiveRecord::Migration
  def change
    remove_column :draft_content_items, :version
    remove_column :live_content_items, :version
    remove_column :link_sets, :version
  end
end
