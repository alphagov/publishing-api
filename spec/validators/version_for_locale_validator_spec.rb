require "rails_helper"

RSpec.describe VersionForLocaleValidator do
  let(:version) { 5 }
  let(:locale) { "en" }

  let(:edition) do
    FactoryGirl.create(
      :edition,
      user_facing_version: version,
      locale: locale,
    )
  end

  describe "#validate" do
    subject(:validate) { described_class.new.validate(edition) }

    context "when it's missing a content item" do
      it { is_expected.to be_nil }
    end

    context "when locale is nil" do
      before { edition.locale = nil }
      it { is_expected.to be_nil }
    end

    context "when version number is nil" do
      before { edition.user_facing_version = nil }
      it { is_expected.to be_nil }
    end

    context "when version, locale and content_id are the same" do
      let!(:conflict_edition) {
        FactoryGirl.create(
          :edition,
          content_id: edition.content_id,
          locale: "fr",
          user_facing_version: version,
        )
      }
      let(:expected_error) do
        "user_facing_version=#{version} and locale=fr for content item=" +
          "#{edition.content_id} conflicts with content item " +
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
end
