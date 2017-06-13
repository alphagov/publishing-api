class AddOwningDocumentIdToDocuments < ActiveRecord::Migration[5.1]
  def up
    add_column :documents, :owning_document_id, :integer, index: true
  end

  def down
    remove_column :documents, :owning_document_id
  end
end
