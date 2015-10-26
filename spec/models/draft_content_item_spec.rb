require 'rails_helper'

RSpec.describe DraftContentItem do
  subject { FactoryGirl.build(:draft_content_item) }

  def set_new_attributes(item)
    item.title = "New title"
  end

  def verify_new_attributes_set
    expect(described_class.last.title).to eq("New title")
  end

  describe ".renderable_content" do
    let!(:guide) { FactoryGirl.create(:draft_content_item, format: "guide", base_path: "/foo") }
    let!(:redirect) { FactoryGirl.create(:draft_content_item, format: "redirect", base_path: "/bar") }
    let!(:gone) { FactoryGirl.create(:draft_content_item, format: "gone", base_path: "/baz") }

    it "returns content items that do not have a format of 'redirect' or 'gone'" do
      expect(described_class.renderable_content).to eq [guide]
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

    it "requires that the content_ids match between draft and live" do
      live_item = FactoryGirl.create(:live_content_item)
      draft_item = live_item.draft_content_item

      draft_item.content_id = "something else"
      expect(draft_item).to be_invalid
    end

    it "requires a format" do
      subject.format = ""
      expect(subject).to be_invalid
    end

    it "requires a publishing_app" do
      subject.publishing_app = ""
      expect(subject).to be_invalid
    end

    context "when the content item is 'renderable'" do
      before do
        subject.format = "guide"
      end

      it "requires a title" do
        subject.title = ""
        expect(subject).to be_invalid
      end

      it "requires a rendering_app" do
        subject.rendering_app = ""
        expect(subject).to be_invalid
      end

      it "requires that the rendering_app is a valid DNS hostname" do
        %w(word alpha12numeric dashed-item).each do |value|
          subject.rendering_app = value
          expect(subject).to be_valid
        end

        ['no spaces', 'puncutation!', 'mixedCASE'].each do |value|
          subject.rendering_app = value
          expect(subject).to be_invalid
          expect(subject.errors[:rendering_app].size).to eq(1)
        end
      end
    end

    context "when the content item is not 'renderable'" do
      before do
        subject.format = "redirect"
      end

      it "does not require a title" do
        subject.title = ""
        expect(subject).to be_valid
      end

      it "does not require a rendering_app" do
        subject.rendering_app = ""
        expect(subject).to be_valid
      end
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
        FactoryGirl.create(:draft_content_item, base_path: "/foo")

        subject.base_path = "/foo"
        expect {
          subject.save!
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'content_id' do
      it "accepts a UUID" do
        subject.content_id = "a7c48dac-f1c6-45a8-b5c1-5c407d45826f"
        expect(subject).to be_valid
      end

      it "does not accept an arbitrary string" do
        subject.content_id = "bacon"
        expect(subject).not_to be_valid
      end

      it "does not accept an empty string" do
        subject.content_id = ""
        expect(subject).not_to be_valid
      end
    end
  end

  let!(:existing) { FactoryGirl.create(:draft_content_item) }

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
