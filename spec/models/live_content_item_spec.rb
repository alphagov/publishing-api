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

    context "#base_path" do
      it "should be required" do
        subject.base_path = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:base_path].size).to eq(1)

        subject.base_path = ''
        expect(subject).not_to be_valid
        expect(subject.errors[:base_path].size).to eq(1)
      end

      it "should be an absolute path" do
        subject.base_path = 'invalid//absolute/path/'
        expect(subject).to_not be_valid
        expect(subject.errors[:base_path].size).to eq(1)
      end

      it "should have a db level uniqueness constraint" do
        FactoryGirl.create(:live_content_item, base_path: "/foo")

        subject.base_path = "/foo"
        expect {
          subject.save!
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  let!(:existing) { FactoryGirl.create(:live_content_item) }

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
