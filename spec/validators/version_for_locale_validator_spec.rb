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
  let(:translation) { Translation.find_by(content_item: content_item) }
  let(:user_facing_version) { UserFacingVersion.find_by(content_item: content_item) }

  describe "#validate" do
    subject { described_class.new.validate(record) }
    context "when it's missing a content item" do
      let(:record) { Translation.new }
      it { is_expected.to be_nil }
    end

    context "when locale is nil" do
      let(:record) { translation }
      before { translation.locale = nil }
      it { is_expected.to be_nil }
    end

    context "when version number is nil" do
      let(:record) { user_facing_version }
      before { user_facing_version.number = nil }
      it { is_expected.to be_nil }
    end

    context "missing translation object" do
      let(:record) { user_facing_version }
      before { translation.destroy }
      it { is_expected.to be_nil }
    end

    context "missing user_facing_version object" do
      let(:record) { translation }
      before { user_facing_version.destroy }
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
      let(:record) { translation }
      let(:expected_error) do
        "user_facing_version=#{version} and locale=fr for content item=" +
          "#{content_item.content_id} conflicts with content item " +
          "id=#{conflict_content_item.id}"
      end
      before do
        translation.locale = "fr"
        subject
      end

      it "adds the error to the content_item attribute" do
        expect(translation.errors[:content_item]).to eq([expected_error])
      end
    end
  end
end
