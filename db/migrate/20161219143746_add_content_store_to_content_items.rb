class AddContentStoreToContentItems < ActiveRecord::Migration[5.0]
  def change
    add_column :content_items, :content_store, :string
  end
end
