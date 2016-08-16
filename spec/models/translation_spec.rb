require "rails_helper"

RSpec.describe Translation do
  describe "validations" do
    let(:locale) { "en" }
    let(:conflict_locale) { "fr" }
    let(:user_facing_version) { 2 }
    let(:conflict_user_facing_version) { 2 }
    let(:state) { "draft" }
    let(:conflict_state) { "published" }

    let!(:content_item) do
      FactoryGirl.create(
        :content_item,
        user_facing_version: user_facing_version,
        locale: locale,
        state: state,
      )
    end

    let!(:conflict_content_item) do
      FactoryGirl.create(
        :content_item,
        content_id: content_item.content_id,
        user_facing_version: conflict_user_facing_version,
        locale: conflict_locale,
        state: conflict_state,
      )
    end

    subject { described_class.find_by!(content_item: content_item) }

    context "when there is a content item with 2 identical versions at the same locale" do
      before { subject.locale = conflict_locale }
      it { is_expected.to be_invalid }
    end

    context "when there is a content item with 2 identical versions at different locales" do
      before { subject.locale = locale }
      it { is_expected.to be_valid }
    end

    context "when there are 2 content items in draft state with different versions" do
      let(:conflict_state) { "draft" }
      let(:conflict_user_facing_version) { 3 }

      context "at the same locale" do
        before { subject.locale = conflict_locale }
        it { is_expected.to be_invalid }
      end

      context "with different locales" do
        before { subject.locale = locale }
        it { is_expected.to be_valid }
      end
    end
  end
end
