require "rails_helper"

RSpec.describe VersionForDocumentValidator do
  let(:version) { 5 }
  let(:document) { FactoryGirl.create(:document) }

  let(:content_item) do
    FactoryGirl.build(:content_item,
      document: document,
      user_facing_version: version,
    )
  end

  describe "#validate" do
    subject(:validate) { described_class.new.validate(content_item) }

    context "when it's missing a content item" do
      it { is_expected.to be_nil }
    end

    context "when document is nil" do
      before { content_item.document_id = nil }
      it { is_expected.to be_nil }
    end

    context "when version number is nil" do
      before { content_item.user_facing_version = nil }
      it { is_expected.to be_nil }
    end

    context "when version and document are the same" do
      let!(:conflict_content_item) {
        FactoryGirl.create(:content_item,
          document: document,
          user_facing_version: version,
        )
      }
      let(:expected_error) do
        "user_facing_version=#{version} and document=#{document.id} " +
          "conflicts with content item id=#{conflict_content_item.id}"
      end

      before do
        validate
      end

      it "adds the error to the base attribute" do
        expect(content_item.errors[:base]).to eq([expected_error])
      end
    end
  end
end
