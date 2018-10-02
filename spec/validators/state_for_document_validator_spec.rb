require "rails_helper"

RSpec.describe StateForDocumentValidator do
  let(:state_name) { "draft" }
  let(:document) { create(:document) }

  let(:edition) do
    build(:edition,
      state: state_name,
      document: document)
  end

  describe "#validate" do
    subject(:validate) { described_class.new.validate(edition) }

    context "when document is nil" do
      before { edition.document = nil }
      it { is_expected.to be_nil }
    end

    context "when state is nil" do
      before { edition.state = nil }
      it { is_expected.to be_nil }
    end

    context "when state and document can conflict" do
      [
        { factory: :draft_edition, state: "draft", scenario: "both items are drafts" },
        { factory: :live_edition, state: "published", scenario: "both items are published" },
        { factory: :live_edition, state: "unpublished", scenario: "existing item is published and new item is unpublished" },
        { factory: :unpublished_edition, state: "published", name: "existing item is unpublished and new item is published" },
      ].each do |hash|
        context "when #{hash[:scenario]}" do
          let!(:conflict_edition) {
            create(hash[:factory],
              document: document)
          }
          let(:state_name) { hash[:state] }
          let(:expected_error) do
            "state=#{hash[:state]} and document=#{document.id} conflicts " +
              "with edition id=#{conflict_edition.id}"
          end

          before do
            validate
          end

          it "adds the error to the base attribute" do
            expect(edition.errors[:base]).to eq([expected_error])
          end
        end
      end

      context "when state is superseded" do
        let!(:conflict_edition) {
          create(:superseded_edition, document: document)
        }
        let(:state_name) { "superseded" }

        it { is_expected.to be_nil }
      end
    end
  end
end
