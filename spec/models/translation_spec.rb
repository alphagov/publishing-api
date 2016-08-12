require "rails_helper"

RSpec.describe Translation do
  describe "validations" do
    let(:content_item) do
      FactoryGirl.create(
        :content_item,
        user_facing_version: 2,
        locale: "en",
      )
    end

    let(:conflict_content_item) do
      FactoryGirl.create(
        :content_item,
        content_id: content_item.content_id,
        user_facing_version: 2,
        locale: "fr",
      )
    end

    subject { described_class.find_by!(content_item: conflict_content_item) }

    context "when there is a content item with 2 identical versions at the same locale" do
      before { subject.locale = "en" }
      it { is_expected.to be_invalid }
    end

    context "when there is a content item with 2 identical versions at different locales" do
      before { subject.locale = "fr" }
      it { is_expected.to be_valid }
    end
  end
end
