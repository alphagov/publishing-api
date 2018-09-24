require "rails_helper"

RSpec.describe RequeueContent do
  let(:edition) { create(:live_edition, base_path: "/ci1", schema_name: "generic") }

  it "it republishes the edition with the version" do
    expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message).with(
      hash_including(
        title: "VAT rates",
        base_path: "/ci1",
        payload_version: 10
      ),
      routing_key: "generic.bulk.reindex",
      persistent: false
    )

    RequeueContent.perform_async(edition.id, 10)
  end
end
