# Remove a public change note (dated 20 July 2018) for "VAT Notice 708: buildings and construction"
# Ticket: https://govuk.zendesk.com/agent/tickets/2927623
# Page: https://www.gov.uk/government/publications/vat-notice-708-buildings-and-construction
#
# Prior steps:
# Queried `Document` for the `content_id: "5f623c6e-7631-11e4-a3cb-005056011aef"`

class RemoveChangeNote < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    # Find document
    document = Document.where(content_id: "5f623c6e-7631-11e4-a3cb-005056011aef").first

    if document.present?
      live_edition = document.live
      details = live_edition.details
      change_history = details[:change_history]

      details[:change_history] = change_history.drop(1)

      live_edition.save

      if Rails.env.production?
        Commands::V2::RepresentDownstream.new.call(document.content_id)
      end
    end
  end

  def down
    # This migration is not reversible
  end
end
