require 'rails_helper'

RSpec.describe ContentItem do
  subject { FactoryGirl.build(:content_item) }

  def set_new_attributes(item)
    item.title = "New title"
  end

  def verify_new_attributes_set
    expect(described_class.last.title).to eq("New title")
  end

  describe ".renderable_content" do
    let!(:guide) { FactoryGirl.create(:content_item, format: "guide") }
    let!(:redirect) { FactoryGirl.create(:redirect_content_item) }
    let!(:gone) { FactoryGirl.create(:gone_content_item) }

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
        subject.rendering_app = nil
        expect(subject).to be_invalid
      end

      it "requires a rendering_app to have a valid hostname" do
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
      subject { FactoryGirl.build(:redirect_content_item) }

      it "does not require a title" do
        subject.title = ""
        expect(subject).to be_valid
      end

      it "does not require a rendering_app" do
        subject.rendering_app = ""
        expect(subject).to be_valid
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

    context 'phase' do
      it 'defaults to live' do
        expect(described_class.new.phase).to eq('live')
      end

      %w(alpha beta live).each do |phase|
        it "is valid with #{phase} phase" do
          subject.phase = phase
          expect(subject).to be_valid
        end
      end

      it 'is invalid without a phase' do
        subject.phase = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:phase].size).to eq(1)
      end

      it 'is invalid with any other phase' do
        subject.phase = 'not-a-correct-phase'
        expect(subject).to_not be_valid
      end
    end
  end

  it_behaves_like DefaultAttributes
  it_behaves_like WellFormedContentTypesValidator
end
