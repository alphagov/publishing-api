class DedupeEmbeddedSpecialistChangeHistory < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    # Find ChangeNotes which have no edition id and
    # have duplicate documents / notes, these need to be removed first.
    # The only publishing apps affected are specialist publisher and service manual publisher.
    dupe_change_note_scope = ChangeNote.where(edition_id: nil)
                                       .group(:document_id, :note)
                                       .having("COUNT(*) > 1")

    dupe_change_notes_ids = dupe_change_note_scope.pluck("array_agg(id)").flatten
    last_dupe_change_notes_ids = dupe_change_note_scope.pluck("max(id)").flatten
    change_note_ids_to_delete = dupe_change_notes_ids - last_dupe_change_notes_ids

    puts "Deleting #{change_note_ids_to_delete.size} duplicate ChangeNotes"
    puts dupe_change_notes_ids.join(",")

    # Removes around 400 duplicate ChangeNotes.
    ChangeNote.where(id: change_note_ids_to_delete).delete_all

    # Find Editions with duplicates in the details change_history
    # and no change notes.
    specialist_editions = Edition
      .where(publishing_app: "specialist-publisher",
             schema_name:    "specialist_document",
             state:          %w(draft published),
             update_type:    %w(major republish))
      .where(%q(
        NOT EXISTS (
          SELECT 1
          FROM change_notes cn
          WHERE cn.edition_id = editions.id
        )
        AND (
          json_array_length(details->'change_history') > 0
        )
    ))

    # Create ChangeNotes for each unique item of change history.
    specialist_editions.find_each do |edition|
      edition.details[:change_history].each do |history_element|
        ChangeNote.find_or_create_by!(
          document: edition.document,
          note: history_element.fetch(:note)
        ).update!(
          edition: edition,
          public_timestamp: history_element.fetch(:public_timestamp),
        )
      end
    end

    # Find editions with duplicate embedded change history
    # that have ChangeNotes and remove the history.
    dupes_sql = <<-SQL
      SELECT DISTINCT(id)
      FROM editions e
      WHERE e.schema_name = 'specialist_document'
      AND e.publishing_app = 'specialist-publisher'
      AND update_type IN ('major', 'republish')
      AND EXISTS (
        SELECT 1
        FROM change_notes cn
        WHERE cn.edition_id = e.id
      )
      AND json_array_length(e.details->'change_history') > 0
      GROUP BY e.id, json_array_elements(e.details->'change_history')->>'note'
      HAVING COUNT(json_array_elements(e.details->'change_history')->>'note') > 1
    SQL

    edition_ids = ActiveRecord::Base.connection.execute(dupes_sql).values.flatten

    # ~350 Records.
    puts "Found #{edition_ids.size} editions with duplicate change history notes."

    if edition_ids.any?
      scope = Edition.where(id: edition_ids)

      puts "Paths affected:"
      puts scope.pluck(:base_path).uniq.sort

      # Remove Edition#details[:change_history] and represent the Edition
      # downstream, the history will be reconstructed from ChangeNotes.
      scope.each do |edition|
        edition_details = edition.details
        edition_details.delete(:change_history)
        edition.update!(details: edition_details)

        if Rails.env.production?
          Commands::V2::RepresentDownstream.new.call(edition.content_id)
        end
      end
    end
  end
end
