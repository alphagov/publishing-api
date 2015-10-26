class MakeBasePathUnique < ActiveRecord::Migration
  def change
    add_index :draft_content_items, :base_path, unique: true
    add_index :live_content_items, :base_path, unique: true
  end
end
