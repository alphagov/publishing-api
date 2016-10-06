require "rails_helper"

RSpec.describe ContentItem do
  subject { FactoryGirl.build(:content_item) }

  describe ".renderable_content" do
    let!(:guide) { FactoryGirl.create(:content_item, schema_name: "guide") }
    let!(:redirect) { FactoryGirl.create(:redirect_content_item) }
    let!(:gone) { FactoryGirl.create(:gone_content_item) }

    it "returns content items that do not have a schema_name of 'redirect' or 'gone'" do
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

    it "requires a schema_name" do
      subject.schema_name = ""
      expect(subject).to be_invalid
    end

    it "requires a publishing_app" do
      subject.publishing_app = ""
      expect(subject).to be_invalid
    end

    context "when the content item is 'renderable'" do
      before do
        subject.document_type = "guide"
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

        ["no spaces", "puncutation!", "mixedCASE"].each do |value|
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

    context "when the content item is optionally 'renderable'" do
      subject { FactoryGirl.build(:content_item, document_type: "contact") }

      it "does not require a rendering_app" do
        subject.rendering_app = nil
        expect(subject).to be_valid
      end
    end

    context "content_id" do
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

    context "phase" do
      it "defaults to live" do
        expect(described_class.new.phase).to eq("live")
      end

      %w(alpha beta live).each do |phase|
        it "is valid with #{phase} phase" do
          subject.phase = phase
          expect(subject).to be_valid
        end
      end

      it "is invalid without a phase" do
        subject.phase = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:phase].size).to eq(1)
      end

      it "is invalid with any other phase" do
        subject.phase = "not-a-correct-phase"
        expect(subject).to_not be_valid
      end
    end
  end

  context "EMPTY_BASE_PATH_FORMATS" do
    it "defines formats not requiring a base_path attibute" do
      expect(ContentItem::EMPTY_BASE_PATH_FORMATS).to eq(%w(contact government))
    end
  end

  describe "#requires_base_path?" do
    it "doesn't require a base path for 'contact' document_type" do
      subject.document_type = "contact"
      expect(subject.requires_base_path?).to be false
    end

    it "doesn't require a base path for 'government' document_type" do
      subject.document_type = "government"
      expect(subject.requires_base_path?).to be false
    end

    it "requires a base path for other document_types" do
      subject.document_type = "different document type"
      expect(subject.requires_base_path?).to be true
    end
  end

  describe "#details_for_govspeak_conversion" do
    subject do
      FactoryGirl.build(:content_item, details: details)
        .details_for_govspeak_conversion
    end

    let(:html_content) { { content_type: "text/html", content: "<b>Hello</b>" } }
    let(:govspeak_content) { { content_type: "text/govspeak", content: "**Hello**" } }

    context "details has no body" do
      let(:details) { { field: "value" } }
      it { is_expected.to match(details) }
    end

    context "details doesn't have a text/govspeak content type" do
      let(:details) { { body: [html_content] } }
      it { is_expected.to match(details) }
    end

    context "details doesn't have a text/html content type" do
      let(:details) { { body: [govspeak_content] } }
      it { is_expected.to match(details) }
    end

    context "details has text/html and text/govspeak content types" do
      let(:details) { { body: [html_content, govspeak_content] } }
      it { is_expected.to match(body: [govspeak_content]) }
    end

    context "details has govspeak in multiple keys" do
      let(:details) do
        {
          key_1: [html_content, govspeak_content],
          key_2: [govspeak_content, html_content],
          key_3: html_content,
        }
      end
      let(:expected_result) do
        {
          key_1: [govspeak_content],
          key_2: [govspeak_content],
          key_3: html_content,
        }
      end
      it { is_expected.to match(expected_result) }
    end
  end

  it_behaves_like DefaultAttributes
  it_behaves_like WellFormedContentTypesValidator
  it_behaves_like DescriptionOverrides
end
