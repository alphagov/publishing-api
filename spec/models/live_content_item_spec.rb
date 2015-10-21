require "rails_helper"

RSpec.describe LiveContentItem do
  subject { FactoryGirl.build(:live_content_item) }

  def set_new_attributes(item)
    item.title = "New title"
  end

  def verify_new_attributes_set
    expect(described_class.last.title).to eq("New title")
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
  end

  describe "#refreshed_draft_item" do
    let(:content_id) { SecureRandom.uuid }

    let!(:arabic_live) { FactoryGirl.create(:live_content_item, locale: "ar", content_id: content_id) }
    let!(:arabic_draft) { arabic_live.draft_content_item }

    let!(:english_live) { FactoryGirl.create(:live_content_item, locale: "en", content_id: content_id) }
    let!(:english_draft) { english_live.draft_content_item }

    it "finds the corresponding draft item scoped correctly to locale" do
      expect(english_live.refreshed_draft_item).to eq(english_draft)
      expect(arabic_live.refreshed_draft_item).to eq(arabic_draft)
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
