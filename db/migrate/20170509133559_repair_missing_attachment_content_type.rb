class RepairMissingAttachmentContentType < ActiveRecord::Migration[5.0]
  def change
    BASE_PATHS.each do |base_path|
      edition = Edition.where(base_path: base_path).last
      next unless edition
      edition_details = edition.details

      updated_attachments = edition_details[:attachments].map do |attachment|
        attachment[:content_type] = "application/pdf" if attachment[:content_type] == nil
        attachment
      end

      edition_details[:attachments] = updated_attachments
      edition.details = edition_details
      edition.save!
    end
  end

  BASE_PATHS = [
    "/cma-cases/private-motor-insurance-market-investigation",
    "/aaib-reports/piper-pa-28-180e-g-ayar-9-may-1985",
    "/aaib-reports/stampe-sv4a-g-bhyi-24-september-1989",
    "/cma-cases/baa-airports-market-investigation-cc",
    "/aaib-reports/bae-146-300-g-oinv-8-november-2006",
    "/aaib-reports/dh82a-tiger-moth-g-anoh-28-august-1983",
    "/aaib-reports/eaa-biplane-g-bbmh-15-april-2012",
    "/aaib-reports/jetstream-4100-g-maji-1-may-1998"
  ]
end
