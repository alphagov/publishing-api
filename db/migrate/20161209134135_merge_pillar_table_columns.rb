class MergePillarTableColumns < ActiveRecord::Migration[5.0]
  def change
    add_column :content_items, :state, :string
    add_column :content_items, :locale, :string
    add_column :content_items, :user_facing_version, :integer
    add_column :content_items, :base_path, :string
  end
end
