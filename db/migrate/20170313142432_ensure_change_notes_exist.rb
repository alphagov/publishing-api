class EnsureChangeNotesExist < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    payload = {} # fake payload, imagine nothing was given

    Edition
      .where(%q(
        NOT EXISTS (
          SELECT 1
          FROM change_notes
          WHERE change_notes.edition_id = editions.id
        )
        AND (
          (details->'change_history') IS NOT NULL
          OR
          (details->'change_note') IS NOT NULL
        )
      ))
      .find_each do |edition|
        ChangeNote.create_from_edition(payload, edition)
      end
  end
end
