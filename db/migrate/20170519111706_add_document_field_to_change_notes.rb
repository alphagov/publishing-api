class AddDocumentFieldToChangeNotes < ActiveRecord::Migration[5.1]
  def change
    add_column :change_notes, :document_id, :integer
    add_foreign_key :change_notes, :documents, on_delete: :cascade
  end
end
