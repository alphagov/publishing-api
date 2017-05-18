class RemoveDuplicateSpecialistChangeNotes < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    specialist_editions = Edition.where(publishing_app: "specialist-publisher",
                                        schema_name: "specialist_document")
                                 .where.not(state: "draft")

    duplicates = ChangeNote.where(edition: specialist_editions)
                           .group(:content_id, :note, :public_timestamp)
                           .having("count(*) > 1")
                           .pluck("max(edition_id)")

    puts "Removing #{duplicates.size} duplicate change notes for edition ids: #{duplicates.join(',')}"

    ChangeNote.where(edition_id: duplicates).delete_all

    if Rails.env.production?
      content_ids = Edition.with_document.where(id: duplicates).pluck("documents.content_id")
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end
  end
end
