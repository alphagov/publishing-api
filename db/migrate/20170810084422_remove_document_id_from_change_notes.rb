class RemoveDocumentIdFromChangeNotes < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :change_notes, :documents
    remove_column :change_notes, :document_id
  end
end
