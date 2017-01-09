class LinkDocumentsAndEditions < ActiveRecord::Migration[5.0]
  def change
    add_column :content_items, :document_id, :integer
    add_foreign_key :content_items, :documents
  end
end
