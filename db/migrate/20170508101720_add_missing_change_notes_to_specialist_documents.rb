class AddMissingChangeNotesToSpecialistDocuments < ActiveRecord::Migration[5.0]
  def up
    scope = Edition.where(publishing_app: "specialist-publisher",
                          schema_name: "specialist_document",
                          state: "published")
      .with_document
      .where("NOT EXISTS (SELECT * FROM change_notes WHERE content_id::uuid = documents.content_id)")

    scope.each do |edition|
      oldest_edition = Edition.where(document_id: edition.document_id).order(:created_at).first
      ChangeNote.create!(edition: edition,
                         content_id: edition.content_id,
                         public_timestamp: earliest_date_for(oldest_edition),
                         note: "First published.")
    end
  end

private

  def earliest_date_for(edition)
    pub_date = earliest(edition.first_published_at, edition.public_updated_at)
    earliest(pub_date, edition.created_at)
  end

  def earliest(d1, d2)
    [d1, d2].min
  end
end
