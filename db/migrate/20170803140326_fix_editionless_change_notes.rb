class FixEditionlessChangeNotes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  FIRST_PUBLISHED_NOTE = "First published."

  def up
    removed_change_note_ids = []
    reassociated_change_note_ids = []
    document_content_ids = []
    change_history_from_document_editions = {}

    # ~ 1274 change notes without an association to an edition
    ChangeNote.where(edition: nil).find_each do |change_note|
      document = change_note.document
      change_notes_from_document_editions = ChangeNote.where(edition: document.editions)
      change_notes_notes_from_document_editions = change_notes_from_document_editions.pluck(:note)

      # Do any of the document editions already have a matching note?
      if change_notes_notes_from_document_editions.include?(change_note.note)
        if change_note.destroy!
          removed_change_note_ids << change_note.id
          document_content_ids << document.content_id
          next
        end
      end

      # Check if this is a "First published." note.
      # If the edition sequence doesn't have one then assign it to the first edition.
      if change_note.note == FIRST_PUBLISHED_NOTE &&
        !change_notes_notes_from_document_editions.include?(FIRST_PUBLISHED_NOTE)

        change_note_edition = document.editions.order(:public_updated_at).first

        unless ChangeNote.find_by(edition: change_note_edition)
          # Associate the edition with the change note.
          change_note_edition = delete_change_history(change_note_edition)
          change_note.edition = change_note_edition

          if change_note_edition.save! && change_note.save!
            puts "Assigning Edition(id: #{document.editions.first.id}) to ChangeNote(id: #{change_note.id})"
            reassociated_change_note_ids << change_note.id
            document_content_ids << document.content_id
            next
          end
        end
      end

      # Map document.editions change history to a sorted deduplicated array
      unless change_history_from_document_editions.has_key?(document.id)
        change_history_from_document_editions[document.id] = mapped_change_history(document)
      end

      # Cross reference the date and note text of the current change note with a change history
      # item and match this to an edition (with the same document which doesn't have a change note)
      # with a public updated date matching both change note and history item.
      # Failing the presence of a relevant change history item match the change note date to the
      # public updated at date of a change note-less edition (with the same document).
      change_note_date = change_note.public_timestamp.to_date
      matching_editions = document.editions
        .where("public_updated_at >= '#{change_note_date}' and public_updated_at < '#{1.day.since(change_note_date)}'")
        .where.not("exists(select id from change_notes where change_notes.edition_id = editions.id)")

      matching_history_item = change_history_from_document_editions[document.id].find do |item|
        item[:note] == change_note.note && item[:date] == change_note_date
      end

      if matching_history_item
        matching_edition = matching_editions.find { |e| e.public_updated_at.to_date == matching_history_item[:date] }
      else
        matching_edition = matching_editions.find { |e| e.public_updated_at.to_date == change_note_date }
      end

      if matching_edition
        # Associate the edition with the change note.
        matching_edition = delete_change_history(matching_edition)
        change_note.edition = matching_edition
        if matching_edition.save! && change_note.save!
          puts "Assigning Edition(id: #{matching_edition.id}) to ChangeNote(id: #{change_note.id})"
          reassociated_change_note_ids << change_note.id
          document_content_ids << document.content_id
        end
      end
    end

    # Pass over the collection of change notes again as some of the steps above
    # may have assigned a change note to every edition for the same document.
    # Any additional notes for that document can be deleted.
    ChangeNote.where(edition: nil).find_each do |change_note|
      document = change_note.document
      change_notes_from_document_editions = ChangeNote.where(edition: document.editions)

      # Check if the number of change notes assigned to document editions matches
      # the number of editions, this change note can't be reassigned so delete it.
      if change_notes_from_document_editions.count == document.editions.count
        if change_note.destroy!
          removed_change_note_ids << change_note.id
          document_content_ids << document.content_id
        end
      end
    end

    # Delete all the change notes which predate the oldest created_at date
    # for the matching document's editions that have no change notes as
    # these can't ever be matched by date.
    # ~ 847 of these
    old_change_notes = ChangeNote.where(edition: nil)
      .where(
        <<-SQL.strip_heredoc
          public_timestamp < (
            SELECT min(created_at)
            FROM editions
            WHERE editions.document_id = change_notes.document_id
            AND NOT EXISTS(
              SELECT id
              FROM change_notes
              WHERE change_notes.edition_id = editions.id
            )
          )
        SQL
      )

    if old_change_notes.any?
      removed_change_note_ids += old_change_notes.pluck(:id)
      document_content_ids += Document.where(id: old_change_notes.pluck(:document_id).uniq).pluck(:content_id)
      old_change_notes.delete_all
    end

    # This leaves one change note
    edition = Edition.find_by(id: 981901)
    change_note = ChangeNote.find_by(id: 33466)
    if edition && change_note && change_note.edition.nil?
      edition = delete_change_history(edition)
      change_note.edition = edition
      if edition.save! && change_note.save!
        reassociated_change_note_ids << change_note.id
        document_content_ids << edition.document.content_id
      end
    end

    if Rails.env.production?
     Commands::V2::RepresentDownstream.new.call(document_content_ids.uniq)
    end

    puts "Removed #{removed_change_note_ids.size} ChangeNotes."
    puts "Reassociated #{reassociated_change_note_ids.size} ChangeNotes to document editions."
  end

private

  def mapped_change_history(document)
    history = document.editions.map { |e| e.details[:change_history] }
    history = history.flatten.compact
    history = history.sort { |a,b| a[:public_timestamp] <=> b[:public_timestamp] }
    history = history.map { |ch| { note: ch[:note], date: ch[:public_timestamp].to_date } }
    history.uniq
  end

  def delete_change_history(edition)
    edition_details = edition.details
    edition_details.delete(:change_history)
    edition.details = edition_details
    edition
  end
end
