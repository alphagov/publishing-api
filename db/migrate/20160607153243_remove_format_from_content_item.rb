class RemoveFormatFromContentItem < ActiveRecord::Migration
  def change
    remove_column :content_items, :format, :string
  end
end
