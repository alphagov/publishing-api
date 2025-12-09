class AddDocumentIdToChangeNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :change_notes, :document_id, :integer
  end
end
