class RepairMissingAttachmentUrls < ActiveRecord::Migration[5.0]
  def up
    ATTACHMENT_URLS.each do |item|
      edition = Edition.where(base_path: item[:edition_slug]).order(:created_at).last
      next unless edition

      edition_details = edition.details

      updated_attachments = edition_details[:attachments].map do |attachment|
        attachment[:url] = item[:url] if attachment[:content_id] == item[:content_id]
        attachment
      end

      edition_details[:attachments] = updated_attachments

      edition.details = edition_details

      edition.save!
    end

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.(content_ids_to_represent)
    end
  end

  def down
    ATTACHMENT_URLS.each do |item|
      edition = Edition.where(base_path: item[:edition_slug]).order(:created_at).last
      next unless edition

      edition_details = edition.details

      updated_attachments = edition_details[:attachments].map do |attachment|
        attachment[:url] = nil if attachment[:content_id] == item[:content_id]
        attachment
      end

      edition_details[:attachments] = updated_attachments

      edition.details = edition_details

      edition.save!
    end
  end

  def content_ids_to_represent
    ATTACHMENT_URLS.map { |attachment| attachment[:content_id] }
  end

  ATTACHMENT_URLS = [
    {
      url: "https://assets.publishing.service.gov.uk/media/5329df39e5274a226800032d/140211_mclaren_autobdy_response_to_provisional_findings_and_remedies_notice.pdf",
      content_id: "7aaa1da9-7d5d-4de8-8915-c492e5d55660",
      edition_slug: "/cma-cases/private-motor-insurance-market-investigation"
    },
    {
      url:
      "https://assets.publishing.service.gov.uk/media/5329df39e5274a226b000279/140211_mike_dickinson_response_to_remedies_notice.pdf",
      content_id: "26b8ce1b-f2a0-460b-afea-abd1d1d36cbd",
      edition_slug: "/cma-cases/private-motor-insurance-market-investigation"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/5329df39ed915d0e60000299/140211_lv_response_to_remedies_notice.pdf",
      content_id: "d8ed79ce-a9db-461d-a5f7-374f8474e6ff",
      edition_slug: "/cma-cases/private-motor-insurance-market-investigation"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/5329df3d40f0b60a76000306/140211_motor_accident_solicitors_society_response_to_remedies_notice.pdf",
      content_id: "2fb12fe2-33f3-4b8b-bae6-218e57b3a9c4",
      edition_slug: "/cma-cases/private-motor-insurance-market-investigation"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/5422fa4e40f0b61342000701/Piper_PA_28-180E_G-AYAR_06-85.pdf",
      content_id: "50a28e26-f665-4f2f-a538-8c9dbf9d18cf",
      edition_slug: "/aaib-reports/piper-pa-28-180e-g-ayar-9-may-1985"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/5422fa4fe5274a13170007df/Stampe_SV4A_G-BHYI_01-90.pdf",
      content_id: "b1a5a48e-4a53-4ea8-8bef-0efad84315f5",
      edition_slug: "/aaib-reports/stampe-sv4a-g-bhyi-24-september-1989"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/55194cf5e5274a142e0003d1/final_undertakings_combined_documents.pdf",
      content_id: "1f3980d0-c586-4444-967b-8ecacb73ff08",
      edition_slug: "/cma-cases/baa-airports-market-investigation-cc"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/55194cf2ed915d142700041f/110418_aberdeen_final_undertakings.pdf",
      content_id: "012fb174-d895-41f4-a4ca-f146eab422b9",
      edition_slug: "/cma-cases/baa-airports-market-investigation-cc"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/5422f821ed915d13710006a7/BAe_146-300__G-OINV_06-07.pdf",
      content_id: "859d6be2-a4a1-45ea-adc3-bba82b876ec1",
      edition_slug: "/aaib-reports/bae-146-300-g-oinv-8-november-2006"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/5422fa5140f0b61346000821/DH82A_Tiger_Moth_G-ANOH_02-84.pdf",
      content_id: "706683e6-3503-49ca-9b7e-60754a4b3475",
      edition_slug: "/aaib-reports/dh82a-tiger-moth-g-anoh-28-august-1983"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/58ecdab0ed915d1f6f000000/EAA_Biplane_G-BBMH_08-12.pdf",
      content_id: "4a2098ca-5f43-4e64-8d21-d3034441ec06",
      edition_slug: "/aaib-reports/eaa-biplane-g-bbmh-15-april-2012"
    },
    {
      url: "https://assets.publishing.service.gov.uk/media/58ecdac1ed915d2010000000/dft_avsafety_pdf_501618.pdf",
      content_id: "9729a8a4-d411-40d1-836a-339133b60332",
      edition_slug: "/aaib-reports/jetstream-4100-g-maji-1-may-1998"
    }
  ]
end
