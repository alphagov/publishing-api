class AddIndexOnChangeNotesDocumentId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :change_notes,
              :document_id,
              where: "public_timestamp IS NOT NULL",
              algorithm: :concurrently,
              name: "idx_change_notes_document_id_partial"
  end
end
