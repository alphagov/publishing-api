class PillarColumnDefaults < ActiveRecord::Migration[5.0]
  def up
    change_column :content_items, :state, :string, null: false
    change_column :content_items, :locale, :string, null: false
    change_column :content_items, :user_facing_version, :integer, null: false, default: 1
  end

  def down
    change_column :content_items, :state, :string
    change_column :content_items, :locale, :string
    change_column :content_items, :user_facing_version, :integer
  end
end
