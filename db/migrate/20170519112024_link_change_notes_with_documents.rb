class LinkChangeNotesWithDocuments < ActiveRecord::Migration[5.1]
  def up
    sql1 = <<-SQL
      UPDATE change_notes
      SET document_id = editions.document_id
      FROM editions
      WHERE editions.id = change_notes.edition_id
    SQL

    ActiveRecord::Base.connection.execute(sql1)

    sql2 = <<-SQL
      UPDATE change_notes
      SET document_id = documents.id
      FROM documents
      WHERE documents.content_id = change_notes.content_id::uuid
        AND documents.locale = 'en'
        AND change_notes.edition_id IS NULL
    SQL

    ActiveRecord::Base.connection.execute(sql2)
  end

  def down
    ChangeNote.update_all(document_id: nil)
  end
end
