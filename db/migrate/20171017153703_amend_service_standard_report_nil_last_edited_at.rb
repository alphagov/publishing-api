class AmendServiceStandardReportNilLastEditedAt < ActiveRecord::Migration[5.1]
  def up
    # ~22 editions
    count = Edition.where(last_edited_at: nil,
                          publishing_app: "specialist-publisher",
                          document_type: "service_standard_report",
                          state: %w(draft published unpublished))
                   .update_all("last_edited_at = public_updated_at")

    puts "#{count} editions updated."
  end
end
