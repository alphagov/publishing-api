require "rails_helper"

RSpec.describe VersionForLocaleValidator do
  let(:version) { 5 }
  let(:locale) { "en" }

  let(:content_item) do
    FactoryGirl.create(
      :content_item,
      user_facing_version: version,
      locale: locale,
    )
  end

  describe "#validate" do
    subject(:validate) { described_class.new.validate(content_item) }

    context "when it's missing a content item" do
      it { is_expected.to be_nil }
    end

    context "when locale is nil" do
      before { content_item.locale = nil }
      it { is_expected.to be_nil }
    end

    context "when version number is nil" do
      before { content_item.user_facing_version = nil }
      it { is_expected.to be_nil }
    end

    context "when version, locale and content_id are the same" do
      let!(:conflict_content_item) {
        FactoryGirl.create(
          :content_item,
          content_id: content_item.content_id,
          locale: "fr",
          user_facing_version: version,
        )
      }
      let(:expected_error) do
        "user_facing_version=#{version} and locale=fr for content item=" +
          "#{content_item.content_id} conflicts with content item " +
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
end
