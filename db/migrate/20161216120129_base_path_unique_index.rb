class BasePathUniqueIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :content_items, [:base_path, :content_store], unique: true
  end
end
