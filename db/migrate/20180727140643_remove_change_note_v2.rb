# Remove a public change note (dated 20 July 2018) for "VAT Notice 708: buildings and construction"
# Ticket: https://govuk.zendesk.com/agent/tickets/2927623
# Page: https://www.gov.uk/government/publications/vat-notice-708-buildings-and-construction
#
# This was previously attempted in #1293 but didn't work when run on integration or staging.
# This is designed to replace that failed migration
#
# Prior steps:
# Queried `Document` for the `content_id: "5f623c6e-7631-11e4-a3cb-005056011aef"`

class RemoveChangeNoteV2 < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    # Find document
    change_note_to_delete = "VAT Notice 308 has been amended to show that a dwelling can consist of more than one building."
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
