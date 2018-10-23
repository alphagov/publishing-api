# Remove a public change note (dated 19 October 2018) for "Condition Improvement Fund"
# Ticket: https://govuk.zendesk.com/agent/tickets/3409998
# Page: https://www.gov.uk/guidance/condition-improvement-fund
#
# Prior steps:
# Queried `Document` for the `content_id: "6022c077-7631-11e4-a3cb-005056011aef"`

class RemoveChangeNoteImprovementFund < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  change_note_to_delete = "Application round for 2019 to 2020 funding now open."

  def up
    # Find document
    document = Document.where(content_id: "5f623c6e-7631-11e4-a3cb-005056011aef").first

    if document.present?
      edition_id = document.live.id
      edition = Edition.find(edition_id)

      if edition.present?
        edition_details = edition.details
        new_details = edition_details
        new_details[:change_history] = new_details[:change_history].delete_if { |history| history[:note] == change_note_to_delete }
        edition.update!(details: new_details)

        if Rails.env.production?
          Commands::V2::RepresentDownstream.new.call(document.content_id)
        end
      end
    end
  end

  def down
    # This migration is not reversible
  end
end
