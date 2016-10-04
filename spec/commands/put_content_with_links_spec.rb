require "rails_helper"

RSpec.describe Commands::PutContentWithLinks do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  let(:payload) {
    {
      content_id: content_id,
      base_path: base_path,
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      format: "guide",
      locale: "en",
      routes: [{ path: base_path, type: "exact" }],
      redirects: [],
      phase: "beta",
      links: {},
    }
  }

  context "when a content_id is not provided" do
    before do
      payload[:content_id] = nil
    end

    it "responds successfully" do
      result = described_class.call(payload)
      expect(result).to be_a(Commands::Success)
    end
  end

  context "when links is not provided" do
    before do
      payload[:links] = nil
    end

    it "responds successfully" do
      result = described_class.call(payload)
      expect(result).to be_a(Commands::Success)
    end
  end

  context "when using document_type and schema_name instead of format" do
    before do
      payload[:format] = nil
      payload[:document_type] = "guide"
      payload[:schema_name] = "guide"
    end

    it "responds successfully" do
      result = described_class.call(payload)
      expect(result).to be_a(Commands::Success)
    end
  end

  it "responds successfully" do
    result = described_class.call(payload)
    expect(result).to be_a(Commands::Success)
  end

  it "saves a content item" do
    expect {
      described_class.call(payload)
    }.to change(ContentItem, :count).by(1)
  end

  context "when the downstream flag is set to false" do
    it "does not send any downstream requests" do
      expect(DownstreamDraftWorker).not_to receive(:perform_async)
      expect(DownstreamLiveWorker).not_to receive(:perform_async)

      described_class.call(payload, downstream: false)
    end
  end

  context "when there is an existing link set for the content_id" do
    let(:target_id) { SecureRandom.uuid }

    before do
      link_set = FactoryGirl.create(
        :link_set,
        content_id: content_id,
        links: [
          FactoryGirl.create(
            :link,
            link_type: "related",
            target_content_id: target_id
          )
        ]
      )

      FactoryGirl.create(:lock_version, target: link_set)
    end

    it "preserves links" do
      expect {
        described_class.call(payload)
      }.not_to change(Link, :count)
    end
  end
end
