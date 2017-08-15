class RemoveFormatFromContentItem < ActiveRecord::Migration[4.2]
  def change
    remove_column :content_items, :format, :string
  end
end
