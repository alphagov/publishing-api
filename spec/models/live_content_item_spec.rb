require "rails_helper"

RSpec.describe LiveContentItem do
  subject { FactoryGirl.build(:live_content_item) }

  def set_new_attributes(item)
    item.title = "New title"
  end

  def verify_new_attributes_set
    expect(described_class.first.title).to eq("New title")
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

    it "requires a version" do
      subject.version = nil
      expect(subject).to be_invalid
    end

    context "given a version number greater than the draft" do
      let(:live) { FactoryGirl.create(:live_content_item, version: 6) }

      it "is invalid" do
        live.version = 7
        expect(live).to be_invalid
      end
    end
  end


  let(:existing) { create(described_class) }
  let(:draft) { existing.draft_content_item }
  let(:content_id) { existing.content_id }

  let(:payload) do
    build(described_class)
    .as_json
    .merge(
      content_id: content_id,
      title: "New title",
      draft_content_item: draft
    )
  end

  it_behaves_like Replaceable
  it_behaves_like DefaultAttributes
  it_behaves_like ImmutableBasePath
end
