class MakeChangeNotesDocumentFieldNotNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null :change_notes, :document_id, false
  end
end
