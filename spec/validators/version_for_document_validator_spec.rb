require "rails_helper"

RSpec.describe VersionForDocumentValidator do
  let(:version) { 5 }
  let(:document) { create(:document) }

  let(:edition) do
    build(
      :edition,
      document: document,
      user_facing_version: version,
    )
  end

  describe "#validate" do
    subject(:validate) { described_class.new.validate(edition) }

    context "when it's missing a edition" do
      it { is_expected.to be_nil }
    end

    context "when document is nil" do
      before { edition.document_id = nil }
      it { is_expected.to be_nil }
    end

    context "when version number is nil" do
      before { edition.user_facing_version = nil }
      it { is_expected.to be_nil }
    end

    context "when version and document are the same" do
      let!(:conflict_edition) do
        create(
          :edition,
          document: document,
          user_facing_version: version,
        )
      end
      let(:expected_error) do
        "user_facing_version=#{version} and document=#{document.id} " \
          "conflicts with edition id=#{conflict_edition.id}"
      end

      before do
        validate
      end

      it "adds the error to the base attribute" do
        expect(edition.errors[:base]).to eq([expected_error])
      end
    end
  end
end
