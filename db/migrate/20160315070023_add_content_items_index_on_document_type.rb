class AddContentItemsIndexOnDocumentType < ActiveRecord::Migration
  def change
    add_index :content_items, :document_type
  end
end
