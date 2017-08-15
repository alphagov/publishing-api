class MakeBasePathUnique < ActiveRecord::Migration[4.2]
  def change
    add_index :draft_content_items, :base_path, unique: true
    add_index :live_content_items, :base_path, unique: true
  end
end
