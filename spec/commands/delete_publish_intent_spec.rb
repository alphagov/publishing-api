require "rails_helper"

RSpec.describe Commands::DeletePublishIntent do
  before do
    stub_request(:delete, %r{.*content-store.*/publish-intent/.*})
  end

  let(:payload) do
    {
      base_path: "/vat-rates",
    }
  end

  it "responds successfully" do
    result = described_class.call(payload)
    expect(result).to be_a(Commands::Success)
  end

  context "when the downstream flag is set to false" do
    it "does not send any downstream requests" do
      expect(PublishingAPI.service(:live_content_store)).not_to receive(:delete_publish_intent)
      expect(PresentedContentStoreWorker).not_to receive(:perform_async)
      expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

      described_class.call(payload, downstream: false)
    end
  end
end
