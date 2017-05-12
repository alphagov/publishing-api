class RemoveEmptySpecialistPublisherChangeHistory < ActiveRecord::Migration[5.0]
  def up
    scope = Edition.where(publishing_app: "specialist-publisher",
                          schema_name: "specialist_document")
                   .where.not(state: "draft")
                   .where("details ->> 'change_history' = '[]'")
                   .order("user_facing_version ASC")

    scope.each do |edition|
      change_notes = ChangeNote
        .where(content_id: edition.content_id)
        .where("edition_id IS NULL OR edition_id IN (?)", edition_ids(edition))
        .order(:public_timestamp)
        .pluck(:note, :public_timestamp)
        .map { |note, timestamp| { note: note, public_timestamp: timestamp } }

      if change_notes.empty?
        change_notes = [
          ChangeNote.create!(edition: edition,
                           content_id: edition.content_id,
                           public_timestamp: earliest_date_for(edition),
                           note: "First published.")
        ]
      end

      edition_details = edition.details
      edition_details[:change_history] = SymbolizeJSON.symbolize(change_notes.as_json)
      edition.update!(details: edition_details)
    end

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(scope.all.map(&:content_id))
    end
  end

private

  def earliest_date_for(edition)
    pub_date = earliest(edition.first_published_at, edition.public_updated_at)
    earliest(pub_date, edition.created_at)
  end

  def earliest(d1, d2)
    [d1, d2].compact.min
  end

  def edition_ids(edition)
    Edition.with_document
      .where("documents.content_id": edition.content_id)
      .where("user_facing_version <= ?", edition.user_facing_version)
      .pluck(:id)
  end
end
