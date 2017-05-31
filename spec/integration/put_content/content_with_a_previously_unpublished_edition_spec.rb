require "rails_helper"

RSpec.describe "PUT /v2/content when creating a draft for a previously unpublished edition" do
  include_context "PutContent call"

  before do
    FactoryGirl.create(:unpublished_edition,
      document: FactoryGirl.create(:document, content_id: content_id, stale_lock_version: 2),
      user_facing_version: 5,
      base_path: base_path,
    )
  end

  it "creates the draft's lock version using the unpublished lock version as a starting point" do
    put "/v2/content/#{content_id}", params: payload.to_json

    edition = Edition.last

    expect(edition).to be_present
    expect(edition.document.content_id).to eq(content_id)
    expect(edition.state).to eq("draft")
    expect(edition.document.stale_lock_version).to eq(3)
  end

  it "creates the draft's user-facing version using the unpublished user-facing version as a starting point" do
    put "/v2/content/#{content_id}", params: payload.to_json

    edition = Edition.last

    expect(edition).to be_present
    expect(edition.document.content_id).to eq(content_id)
    expect(edition.state).to eq("draft")
    expect(edition.user_facing_version).to eq(6)
  end

  it "allows the setting of first_published_at" do
    explicit_first_published = DateTime.new(2016, 05, 23, 1, 1, 1).rfc3339
    payload[:first_published_at] = explicit_first_published

    put "/v2/content/#{content_id}", params: payload.to_json

    edition = Edition.last

    expect(edition).to be_present
    expect(edition.document.content_id).to eq(content_id)
    expect(edition.first_published_at).to eq(explicit_first_published)
  end
end
