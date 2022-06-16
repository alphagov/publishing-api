RSpec.describe Tasks::DataSanitizer do
  let!(:non_limited_draft) do
    create(:draft_edition, base_path: "/non-limited-draft")
  end

  let!(:limited_draft) do
    create(
      :access_limited_draft_edition,
      base_path: "/limited-draft",
    )
  end

  let!(:live_edition) do
    create(:live_edition, base_path: "/live-item")
  end

  let(:stdout) { double(:stdout, puts: nil) }

  before do
    stub_request(:any, %r{.*draft-content-store.*/content/.*})
  end

  it "deletes all access limited drafts" do
    Tasks::DataSanitizer.delete_access_limited(stdout)

    expect(Edition.exists?(limited_draft.id)).to eq(false)
    expect(Edition.exists?(non_limited_draft.id)).to eq(true)
    expect(Edition.exists?(live_edition.id)).to eq(true)
  end

  it "deletes access limited drafts from the draft content store" do
    expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
      .with("/limited-draft")

    Tasks::DataSanitizer.delete_access_limited(stdout)
  end

  it "removes the limited draft" do
    expect {
      Tasks::DataSanitizer.delete_access_limited(stdout)
    }.to change(Edition, :count).by(-1)

    expect(Edition.exists?(limited_draft.id)).to eq(false)
    expect(AccessLimit.count).to be_zero
  end
end
