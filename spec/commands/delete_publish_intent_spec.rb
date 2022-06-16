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
      expect(DownstreamDraftWorker).not_to receive(:perform_async)
      expect(DownstreamLiveWorker).not_to receive(:perform_async)

      described_class.call(payload, downstream: false)
    end
  end
end
