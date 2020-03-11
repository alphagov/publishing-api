class FixWhitehallRemoveChangeNote < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    # Find change notes
    d = Document.where(content_id: "b3b96cb9-e7fa-493c-87a5-31d71d79c7a7").first
    if d.present?
      change_notes = d.editions.map(&:change_note).compact
      change_notes.select! { |change_note| change_note.note == "Added funding allocations for individual LAs for 2018 to 2019." }

      # Get rid of change notes
      change_notes.map(&:destroy)

      # Re-present editions to content store
      content_ids = change_notes.map(&:edition_id)
      puts "The editions that need to be represented downstream are: #{content_ids}"

      if Rails.env.production?
        Commands::V2::RepresentDownstream.new.call(content_ids)
      end
    end
  end

  def down
    # This migration is not reversible
  end
end
