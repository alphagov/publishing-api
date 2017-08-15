class AddContentItemsIndexOnDocumentType < ActiveRecord::Migration[4.2]
  def change
    add_index :content_items, :document_type
  end
end
