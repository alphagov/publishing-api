require 'rails_helper'

RSpec.describe DraftContentItem do
  subject { FactoryGirl.build(:draft_content_item) }

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

    it "requires a content_id" do
      subject.content_id = nil
      expect(subject).to be_invalid
    end

    it "requires that the content_ids match between draft and live" do
      live_item = FactoryGirl.create(:live_content_item)
      draft_item = live_item.draft_content_item

      draft_item.content_id = "something else"
      expect(draft_item).to be_invalid
    end
  end

  describe "#refreshed_live_item" do
    let(:content_id) { SecureRandom.uuid }

    let!(:arabic_live) { FactoryGirl.create(:live_content_item, locale: "ar", content_id: content_id) }
    let!(:arabic_draft) { arabic_live.draft_content_item }

    let!(:english_live) { FactoryGirl.create(:live_content_item, locale: "en", content_id: content_id) }
    let!(:english_draft) { english_live.draft_content_item }

    it "finds the corresponding live item scoped correctly to locale" do
      expect(english_draft.refreshed_live_item).to eq(english_live)
      expect(arabic_draft.refreshed_live_item).to eq(arabic_live)
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
