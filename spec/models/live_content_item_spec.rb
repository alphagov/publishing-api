require "rails_helper"

RSpec.describe LiveContentItem do
  subject { FactoryGirl.build(:live_content_item) }

  def set_new_attributes(item)
    item.title = "New title"
  end

  def verify_new_attributes_set
    expect(described_class.last.title).to eq("New title")
  end

  describe "versioning" do
    it "copies the version from the draft content item on save" do
      draft = subject.draft_content_item
      draft.update!(version: 5) # <-- this actually sets it to 6

      subject.save!
      expect(subject.reload.version).to eq(6)
    end
  end

  describe "validations" do
    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a draft_content_item" do
      subject.draft_content_item = nil
      expect(subject).to be_invalid
    end

    it "requires a content_id" do
      subject.content_id = nil
      expect(subject).to be_invalid
    end

    it "requires that the content_ids match" do
      subject.content_id = "something else"
      expect(subject).to be_invalid
    end

    it "does not allow you to change the record's version" do
      expect {
        subject.version = 123
      }.to raise_error(UnassignableVersionError)
    end

    describe "comparing versions when the draft content item is stale" do
      let(:live) { FactoryGirl.create(:live_content_item) }
      let(:draft) { live.draft_content_item }

      before do
        another_instance = described_class.find(live.id)
        another_instance.draft_content_item.save!
      end

      it "sets the live version from the latest persisted draft version" do
        live.save!
        expect(live.version).to eq(DraftContentItem.last.version)
      end
    end
  end

  let(:existing) { FactoryGirl.create(:live_content_item) }

  let(:draft) { existing.draft_content_item }
  let(:content_id) { existing.content_id }
  let(:payload) do
    FactoryGirl.build(:live_content_item)
    .as_json
    .symbolize_keys
    .merge(
      content_id: content_id,
      title: "New title",
      draft_content_item: draft
    )
  end

  let(:another_draft) { FactoryGirl.create(:draft_content_item) }
  let(:another_content_id) { another_draft.content_id }
  let(:another_payload) do
    FactoryGirl.build(:live_content_item)
    .as_json
    .symbolize_keys
    .merge(
      content_id: another_content_id,
      title: "New title",
      draft_content_item: another_draft
    )
  end

  it_behaves_like Replaceable
  it_behaves_like DefaultAttributes
  it_behaves_like ImmutableBasePath
end
