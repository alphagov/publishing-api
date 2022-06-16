RSpec.describe "Queue rake task" do
  before do
    Rake::Task["queue:preview_recent_message"].reenable
  end

  it "previews the rabbit MQ message for a document type" do
    edition = create(:live_edition, base_path: "/ci1")
    create(:event, id: 12)

    expect_any_instance_of(Object).to receive(:pp).with(
      hash_including(title: "VAT rates", payload_version: 12),
    )
    Rake::Task["queue:preview_recent_message"].invoke(edition.document_type)
  end
end
