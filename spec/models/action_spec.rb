require "rails_helper"

RSpec.describe Action do
  describe "Content Item and Link Set presence" do
    let(:content_item) { nil }
    let(:link_set) { nil }
    subject { FactoryGirl.build(:action, edition: content_item, link_set: link_set) }

    context "No Content Item or Link Set" do
      it { is_expected.to be_valid }
    end

    context "Content Item and no Link Set" do
      let(:content_item) { FactoryGirl.create(:content_item) }
      it { is_expected.to be_valid }
    end

    context "Content Item and no Link Set" do
      let(:link_set) { FactoryGirl.create(:link_set) }
      it { is_expected.to be_valid }
    end

    context "Content Item and Link Set" do
      let(:content_item) { FactoryGirl.create(:content_item) }
      let(:link_set) { FactoryGirl.create(:link_set) }
      it { is_expected.not_to be_valid }
    end
  end
end
