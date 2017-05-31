
RSpec.describe "PUT /v2/content when the payload is for a brand new edition" do
  include_context "PutContent call"

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

  shared_examples "creates a change note" do
    it "creates a change note" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change { ChangeNote.count }.by(1)
    end
  end

  context "and the change node is in the payload" do
    include_examples "creates a change note"
  end

  context "and the change history is in the details hash" do
    before do
      payload.delete(:change_note)
      payload[:details] = { change_history: [change_note] }
    end

    include_examples "creates a change note"
  end

  context "and the change note is in the details hash" do
    before do
      payload.delete(:change_note)
      payload[:details] = { change_note: change_note[:note] }
    end

    include_examples "creates a change note"
  end
end
