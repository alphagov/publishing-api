# Remove a public change note (dated 19 October 2018) for "Condition Improvement Fund"
# Ticket: https://govuk.zendesk.com/agent/tickets/3409998
# Page: https://www.gov.uk/guidance/condition-improvement-fund
#
# Prior steps:
# Queried `Document` for the `content_id: "6022c077-7631-11e4-a3cb-005056011aef"`

class RemoveChangeNoteImprovementFund < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  
  def up
    # Find change notes
    d = Document.where(content_id: "6022c077-7631-11e4-a3cb-005056011aef").first
    if d.present?
      change_notes = d.editions.map(&:change_note).compact
      change_notes.select!{ |change_note| change_note.note == "Application round for 2019 to 2020 funding now open."}
  
      # Get rid of change notes
      change_notes.map(&:destroy)
  
      # Re-present editions to content store
      content_ids = change_notes.map { |change_note| change_note.edition.content_id }
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
