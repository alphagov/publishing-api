require "rails_helper"

RSpec.describe Queries::VersionForLocale do
  let(:base_content_id) { SecureRandom.uuid }
  let(:base_locale) { "en" }
  let(:base_version) { 5 }

  let!(:base_content_item) do
    FactoryGirl.create(
      :content_item,
      content_id: base_content_id,
      locale: base_locale,
      user_facing_version: base_version,
    )
  end

  describe ".conflict" do
    let(:content_item_id) { base_content_item.id + 1 }
    let(:content_id) { base_content_id }
    let(:locale) { base_locale }
    let(:version) { base_version }
    subject { described_class.conflict(content_item_id, content_id, locale, version) }

    context "when checking current item" do
      let(:content_item_id) { base_content_item.id }
      it { is_expected.to be_nil }
    end

    context "when locale is different" do
      let(:locale) { "fr" }
      it { is_expected.to be_nil }
    end

    context "when version is different" do
      let(:version) { base_version + 1 }
      it { is_expected.to be_nil }
    end

    context "when locale and version are the same" do
      context "when content_id is different" do
        let(:content_id) { SecureRandom.uuid }
        it { is_expected.to be_nil }
      end

      context "when content_id is the same" do
        it { is_expected.to eq id: base_content_item.id }
      end
    end
  end
end
