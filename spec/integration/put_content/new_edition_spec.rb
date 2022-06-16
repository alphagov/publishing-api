RSpec.describe "PUT /v2/content when the payload is for a brand new edition" do
  include_context "PutContent call"

  before do
    Timecop.freeze(Time.zone.local(2017, 9, 1, 12, 0, 0))
  end

  after do
    Timecop.return
  end

  subject { Edition.last }

  it "creates an edition" do
    put "/v2/content/#{content_id}", params: payload.to_json

    expect(subject).to be_present
    expect(subject.document.content_id).to eq(content_id)
    expect(subject.title).to eq("Some Title")
  end

  it "sets a draft state for the edition" do
    put "/v2/content/#{content_id}", params: payload.to_json

    expect(subject.state).to eq("draft")
  end

  it "sets a user-facing version of 1 for the edition" do
    put "/v2/content/#{content_id}", params: payload.to_json

    expect(subject.user_facing_version).to eq(1)
  end

  it "creates a lock version for the edition" do
    put "/v2/content/#{content_id}", params: payload.to_json

    expect(subject.document.stale_lock_version).to eq(1)
  end

  it "has a publishing_api_first_published_at of nil" do
    put "/v2/content/#{content_id}", params: payload.to_json

    expect(subject.publishing_api_first_published_at).to be_nil
  end

  it "has a major_published_at of nil" do
    put "/v2/content/#{content_id}", params: payload.to_json
    expect(subject.major_published_at).to be_nil
  end

  it "sets publishing_api_last_edited_at to current time" do
    put "/v2/content/#{content_id}", params: payload.to_json
    expect(subject.publishing_api_last_edited_at).to eq(Time.zone.now)
  end

  it "sets last_edited_at to current time" do
    put "/v2/content/#{content_id}", params: payload.to_json
    expect(subject.last_edited_at).to eq(Time.zone.now)
  end

  shared_examples "creates a change note" do
    it "creates a change note" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change { ChangeNote.count }.by(1)
    end
  end

  context "first_published_at is present in the payload" do
    let(:first_published_at) { Time.zone.now }
    before do
      payload[:first_published_at] = first_published_at
    end

    it "sets first_published_at to first_published_at" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect(subject.first_published_at).to eq(first_published_at)
    end
  end

  context "and the change node is in the payload" do
    include_examples "creates a change note"
  end

  context "and the change history is in the details hash" do
    before do
      payload.delete(:change_note)

      # This needs to be a schema that supports change_history hence news_story
      payload.merge!(
        document_type: "news_story",
        schema_name: "news_article",
        details: {
          body: "News",
          government: { title: "Test", slug: "test", current: true },
          political: false,
          change_history: [
            { note: change_note, public_timestamp: Time.zone.now.utc.rfc3339 },
          ],
        },
      )
    end

    include_examples "creates a change note"
  end
end
