require "rails_helper"

RSpec.describe Tasks::DataSanitizer do
  let!(:non_limited_draft) { FactoryGirl.create(:draft_content_item) }
  let!(:limited_draft) { FactoryGirl.create(:access_limited_draft_content_item) }
  let!(:live_content_item) { FactoryGirl.create(:live_content_item) }
  let(:stdout) { double(:stdout, puts: nil)}

  before do
    stub_request(:any, %r{.*draft-content-store.*/content/.*})
  end

  it "deletes all access limited drafts" do
    Tasks::DataSanitizer.delete_access_limited(stdout)

    expect(DraftContentItem.exists?(limited_draft.id)).to eq(false)
    expect(DraftContentItem.exists?(non_limited_draft.id)).to eq(true)
    expect(LiveContentItem.exists?(live_content_item.id)).to eq(true)
  end

  it "deletes access limited drafts from the draft content store" do
    expect(PublishingAPI.service(:draft_content_store)).to receive(:delete_content_item)
      .with(limited_draft.base_path)

    Tasks::DataSanitizer.delete_access_limited(stdout)
  end

  it "resets drafts to live if available, wiping access limiting" do
    FactoryGirl.create(:live_content_item,
      base_path: limited_draft.base_path,
      content_id: limited_draft.content_id,
      draft_content_item: limited_draft,
      title: "A live content item",
    )

    Tasks::DataSanitizer.delete_access_limited(stdout)

    expect(DraftContentItem.exists?(limited_draft.id)).to eq(true)

    limited_draft.reload

    expect(limited_draft.title).to eq("A live content item")
    expect(limited_draft.access_limited).to eq({})
  end
end
