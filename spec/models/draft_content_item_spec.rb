require 'rails_helper'

RSpec.describe DraftContentItem do
  subject { FactoryGirl.build(:draft_content_item) }

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

    it "requires a version" do
      subject.version = nil
      expect(subject).to be_invalid
    end
  end

  let!(:existing) { create(described_class) }
  let!(:content_id) { existing.content_id }

  let!(:payload) do
    build(described_class)
    .as_json
    .merge(
      content_id: content_id,
      title: "New title"
    )
  end

  it_behaves_like Replaceable
  it_behaves_like DefaultAttributes
  it_behaves_like ImmutableBasePath
end
