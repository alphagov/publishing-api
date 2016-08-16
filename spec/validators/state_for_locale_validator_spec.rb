require "rails_helper"

RSpec.describe StateForLocaleValidator do
  let(:state_name) { "draft" }
  let(:locale) { "en" }

  let(:content_item) do
    FactoryGirl.create(
      :content_item,
      state: state_name,
      locale: locale,
    )
  end
  let(:state_model) { State.find_by(content_item: content_item) }
  let(:translation) { Translation.find_by(content_item: content_item) }

  describe "#validate" do
    subject { described_class.new.validate(record) }
    let(:validate) { subject }

    context "when it's missing a content item" do
      let(:record) { State.new }
      it { is_expected.to be_nil }
    end

    context "when locale is nil" do
      let(:record) { translation }
      before { translation.locale = nil }
      it { is_expected.to be_nil }
    end

    context "when state is nil" do
      let(:record) { state_model }
      before { state_model.name = nil }
      it { is_expected.to be_nil }
    end

    context "missing translation object" do
      let(:record) { state_model }
      before { translation.destroy }
      it { is_expected.to be_nil }
    end

    context "missing state object" do
      let(:record) { translation }
      before { state_model.destroy }
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
          let(:record) { translation }
          let(:expected_error) do
            "state=#{hash[:state]} and locale=fr for content " +
              "item=#{content_item.content_id} conflicts with content item " +
              "id=#{conflict_content_item.id}"
          end

          before do
            translation.locale = "fr"
            validate
          end

          it "adds the error to the content_item attribute" do
            expect(translation.errors[:content_item]).to eq([expected_error])
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
        let(:record) { translation }

        before { translation.locale = "fr" }

        it { is_expected.to be_nil }
      end
    end
  end
end
