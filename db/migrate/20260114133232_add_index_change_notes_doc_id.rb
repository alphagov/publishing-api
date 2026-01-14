class AddIndexChangeNotesDocId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :change_notes, :document_id, algorithm: :concurrently
  end
end
