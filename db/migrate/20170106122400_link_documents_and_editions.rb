class LinkDocumentsAndEditions < ActiveRecord::Migration[5.0]
  def change
    add_column :content_items, :document_id, :integer
    add_foreign_key :content_items, :documents
<<<<<<< 33fbf71cae7dd1fc2d4513db05afc23693e87061
=======

    add_index :content_items, [:document_id, :user_facing_version], unique: true
    add_index :content_items, [:document_id, :content_store], unique: true
    add_index :content_items, [:document_id, :state]
>>>>>>> Reorganise migrations for simplicity
  end
end
