require "rails_helper"

RSpec.describe Commands::PutDraftContentWithLinks do
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

  it "responds successfully" do
    result = described_class.call(payload)
    expect(result).to be_a(Commands::Success)
  end

  it "saves a content item" do
    expect {
      described_class.call(payload)
    }.to change(ContentItem, :count).by(1)
  end

  it "protects certain links from being overwritten" do
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content/foo")
    stub_request(:put, "http://content-store.dev.gov.uk/content/foo")

    link_set = create(:link_set, content_id: '60d81299-6ae7-4bab-b4fe-4235d518d50a')
    lock_version = create(:lock_version, target: link_set)
    protected_link = create(:link, link_set: link_set, link_type: 'alpha_taxons')
    normal_link = create(:link, link_set: link_set, link_type: 'topics')

    described_class.call(
      title: 'Test Title',
      format: 'placeholder',
      content_id: '60d81299-6ae7-4bab-b4fe-4235d518d50a',
      base_path: '/foo',
      publishing_app: 'whitehall',
      rendering_app: 'whitehall',
      public_updated_at: Time.now,
      routes: [{ path: '/foo', type: "exact" }],
      update_type: "minor",
      links: { topics: [] },
    )

    expect { normal_link.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { protected_link.reload }.not_to raise_error
  end
end
