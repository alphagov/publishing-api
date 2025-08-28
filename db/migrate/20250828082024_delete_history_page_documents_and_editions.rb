# This will delete all editions with the following base paths, as well as their parent documents:
#       /government/history/10-downing-street
#       /government/history/11-downing-street
#       /government/history/king-charles-street
#       /government/history/lancaster-house
#       /government/history/1-horse-guards-road
#       /government/history

class DeleteHistoryPageDocumentsAndEditions < ActiveRecord::Migration[8.0]
  def up
    Edition.where(document_type: "history").pluck(:document_id).uniq.each do |document_id|
      document = Document.find(document_id)
      base_path = document.editions.last.base_path

      Rails.logger.info "Deleting editions for document #{document_id}, with base path #{base_path}"
      document.editions.destroy_all

      Rails.logger.info "Deleting document #{document_id}"
      document.destroy!

      Rails.logger.info "Deleting path reservation #{base_path}"
      PathReservation.find_by(base_path: base_path).destroy!
    end
  end
end
