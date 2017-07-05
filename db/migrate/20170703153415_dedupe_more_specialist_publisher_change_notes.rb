class DedupeMoreSpecialistPublisherChangeNotes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    dupe_change_note_ids = ChangeNote.group(:public_timestamp, :note)
                                     .having("COUNT(*) > 1")
                                     .pluck("array_agg(id)")

    document_ids = ChangeNote.where(id: dupe_change_note_ids.flatten,
                                    edition_id: nil)
                             .pluck(:document_id).flatten.uniq

    # ~ 572 specialist-publisher change notes.
    ChangeNote.where(id: dupe_change_note_ids.flatten,
                     edition_id: nil).delete_all

    # Remove Edition#details[:change_history] and represent the Edition
    # downstream, the history will be reconstructed from ChangeNotes.
    Edition.where(document_id: document_ids).each do |edition|
      edition_details = edition.details
      edition_details.delete(:change_history)
      edition.update!(details: edition_details)
    end

    content_ids = Document.where(id: document_ids).pluck(&:content_id)

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
