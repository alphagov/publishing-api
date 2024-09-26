RSpec.describe Commands::DeletePublishIntent do
  before do
    stub_request(:delete, %r{.*content-store.*/publish-intent/.*})
  end

  let(:payload) do
    {
      base_path: "/vat-rates",
    }
  end

  let(:content_store) { PublishingAPI.service(:live_content_store) }

  it "responds successfully" do
    result = described_class.call(payload)
    expect(result).to be_a(Commands::Success)
  end

  context "when the downstream flag is set to false" do
    it "does not send any downstream requests" do
      expect(content_store).not_to receive(:delete_publish_intent)

      described_class.call(payload, downstream: false)
    end
  end

  context "when the downstream flag is set to false" do
    it "does not send any downstream requests" do
      expect(content_store).not_to receive(:delete_publish_intent)

      described_class.call(payload, downstream: false)
    end
  end

  context "when the downstream flag is set to true" do
    context "and the ENQUEUE_PUBLISH_INTENTS flag is true" do
      before do
        ENV["ENQUEUE_PUBLISH_INTENTS"] = "true"
      end

      it "enqueues a DeletePublishIntent job" do
        expect(DeletePublishIntentJob).to receive(:perform_async)
        described_class.call(payload, downstream: true)
      end
    end

    context "and the ENQUEUE_PUBLISH_INTENTS flag is not true" do
      before do
        ENV["ENQUEUE_PUBLISH_INTENTS"] = "no"
      end

      it "does send downstream requests" do
        expect(content_store).to receive(:delete_publish_intent)

        described_class.call(payload, downstream: true)
      end
    end

    context "and the ENQUEUE_PUBLISH_INTENTS flag is not present" do
      before do
        ENV.delete("ENQUEUE_PUBLISH_INTENTS")
      end

      it "does send downstream requests" do
        expect(content_store).to receive(:delete_publish_intent)

        described_class.call(payload, downstream: true)
      end
    end
  end
end
