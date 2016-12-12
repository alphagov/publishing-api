require "rails_helper"

RSpec.describe StateForLocaleValidator do
  let(:state_name) { "draft" }
  let(:locale) { "en" }

  let(:content_item) do
    FactoryGirl.build(
      :content_item,
      state: state_name,
      locale: locale,
    )
  end

  describe "#validate" do
    subject(:validate) { described_class.new.validate(content_item) }

    context "when locale is nil" do
      before { content_item.locale = nil }
      it { is_expected.to be_nil }
    end

    context "when state is nil" do
      before { content_item.state = nil }
      it { is_expected.to be_nil }
    end

    context "when version, state and content_id can conflict" do
      [
        { factory: :draft_content_item, state: "draft", scenario: "both items are drafts" },
        { factory: :live_content_item, state: "published", scenario: "both items are published" },
        { factory: :live_content_item, state: "unpublished", scenario: "existing item is published and new item is unpublished" },
        { factory: :unpublished_content_item, state: "published", name: "existing item is unpublished and new item is published" },
      ].each do |hash|
        context "when #{hash[:scenario]}" do
          let!(:conflict_content_item) {
            FactoryGirl.create(
              hash[:factory],
              content_id: content_item.content_id,
              locale: "fr",
            )
          }
          let(:state_name) { hash[:state] }
          let(:expected_error) do
            "state=#{hash[:state]} and locale=fr for content " +
              "item=#{content_item.content_id} conflicts with content item " +
              "id=#{conflict_content_item.id}"
          end

          before do
            content_item.locale = "fr"
            validate
          end

          it "adds the error to the base attribute" do
            expect(content_item.errors[:base]).to eq([expected_error])
          end
        end
      end

      context "when state is superseded" do
        let!(:conflict_content_item) {
          FactoryGirl.create(
            :superseded_content_item,
            content_id: content_item.content_id,
            locale: "fr",
          )
        }
        let(:state_name) { "superseded" }

        before { content_item.locale = "fr" }

        it { is_expected.to be_nil }
      end
    end
  end
end
