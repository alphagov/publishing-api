# Remove a public change note (dated 19 October 2018) for "Condition Improvement Fund"
# Ticket: https://govuk.zendesk.com/agent/tickets/3409998
# Page: https://www.gov.uk/guidance/condition-improvement-fund
#
# Prior steps:
# Queried `Document` for the `content_id: "6022c077-7631-11e4-a3cb-005056011aef"`

class RemoveChangeNoteImprovementFund < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    # Find document
    document = Document.where(content_id: "6022c077-7631-11e4-a3cb-005056011aef").first

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
