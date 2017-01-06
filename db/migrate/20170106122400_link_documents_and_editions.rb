class LinkDocumentsAndEditions < ActiveRecord::Migration[5.0]
  def change
    add_column :content_items, :document_id, :integer
    add_foreign_key :content_items, :documents

    add_index :content_items, [:document_id, :user_facing_version], unique: true
    add_index :content_items, [:document_id, :content_store], unique: true
    add_index :content_items, [:document_id, :state]
  end
end
