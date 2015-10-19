require 'rails_helper'

RSpec.describe DraftContentItem do
  subject { FactoryGirl.build(:draft_content_item) }

  def set_new_attributes(item)
    item.title = "New title"
  end

  def verify_new_attributes_set
    expect(described_class.last.title).to eq("New title")
  end

  describe "versioning" do
    it "increments the version number when the record is saved" do
      subject.version = 5
      subject.save!

      expect(subject.reload.version).to eq(6)
    end

    it "sets the version to 1 on first save" do
      subject.save!
      expect(subject.reload.version).to eq(1)
    end
  end

  describe "validations" do
    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a content_id" do
      subject.content_id = nil
      expect(subject).to be_invalid
    end

    it "requires that the content_ids match" do
      FactoryGirl.create(
        :live_content_item,
        draft_content_item: subject
      )

      subject.content_id = "something else"
      expect(subject).to be_invalid
    end

    describe "version comparison between draft and live" do
      let(:live) { FactoryGirl.create(:live_content_item, draft_version: 6) }
      let(:draft) { live.draft_content_item }

      it "is invalid if the draft version is less than the live version" do
        draft.version = 4
        expect(draft).to be_invalid
      end

      it "is invalid if the draft version is equal to the live version" do
        draft.version = 5
        expect(draft).to be_invalid
      end

      it "is valid if the draft version is greater than the live version" do
        draft.version = 6
        expect(draft).to be_valid
      end
    end

    it "requires that the version number be higher than its predecessor" do
      subject.version = 5
      subject.save!

      subject.version = 4
      expect(subject).to be_invalid
    end

    describe "comparing versions when the live content item is stale" do
      let(:live) { FactoryGirl.create(:live_content_item) }
      let(:draft) { live.draft_content_item }

      before do
        another_instance = described_class.find(draft.id)
        another_instance.save!
        another_instance.live_content_item.save!
      end

      it "checks the version of live against the database" do
        expect(draft).to be_invalid,
          "The live version has not been checked against the persisted record."
      end
    end
  end

  let(:existing) { FactoryGirl.create(:draft_content_item) }

  let(:content_id) { existing.content_id }
  let(:payload) do
    FactoryGirl.build(:draft_content_item)
    .as_json
    .symbolize_keys
    .merge(
      content_id: content_id,
      title: "New title"
    )
  end

  let(:another_payload) do
    FactoryGirl.build(:draft_content_item)
    .as_json
    .symbolize_keys
    .merge(title: "New title")
  end

  it_behaves_like Replaceable
  it_behaves_like DefaultAttributes
  it_behaves_like ImmutableBasePath
end
