require "rails_helper"

RSpec.describe StateForLocaleValidator do
  let(:state_name) { "draft" }
  let(:locale) { "en" }

  let(:edition) do
    FactoryGirl.build(
      :edition,
      state: state_name,
      locale: locale,
    )
  end

  describe "#validate" do
    subject(:validate) { described_class.new.validate(edition) }

    context "when locale is nil" do
      before { edition.locale = nil }
      it { is_expected.to be_nil }
    end

    context "when state is nil" do
      before { edition.state = nil }
      it { is_expected.to be_nil }
    end

    context "when version, state and content_id can conflict" do
      [
        { factory: :draft_edition, state: "draft", scenario: "both items are drafts" },
        { factory: :live_edition, state: "published", scenario: "both items are published" },
        { factory: :live_edition, state: "unpublished", scenario: "existing item is published and new item is unpublished" },
        { factory: :unpublished_edition, state: "published", name: "existing item is unpublished and new item is published" },
      ].each do |hash|
        context "when #{hash[:scenario]}" do
          let!(:conflict_edition) {
            FactoryGirl.create(
              hash[:factory],
              content_id: edition.content_id,
              locale: "fr",
            )
          }
          let(:state_name) { hash[:state] }
          let(:expected_error) do
            "state=#{hash[:state]} and locale=fr for content " +
              "item=#{edition.content_id} conflicts with content item " +
              "id=#{conflict_edition.id}"
          end

          before do
            edition.locale = "fr"
            validate
          end

          it "adds the error to the base attribute" do
            expect(edition.errors[:base]).to eq([expected_error])
          end
        end
      end

      context "when state is superseded" do
        let!(:conflict_edition) {
          FactoryGirl.create(
            :superseded_edition,
            content_id: edition.content_id,
            locale: "fr",
          )
        }
        let(:state_name) { "superseded" }

        before { edition.locale = "fr" }

        it { is_expected.to be_nil }
      end
    end
  end
end
