require "rails_helper"

RSpec.describe Action do
  describe "edition and link set presence" do
    let(:edition) { nil }
    let(:link_set) { nil }
    subject { FactoryGirl.build(:action, edition: edition, link_set: link_set) }

    context "no edition or link set" do
      it { is_expected.to be_valid }
    end

    context "edition and no link set" do
      let(:edition) { FactoryGirl.create(:edition) }
      it { is_expected.to be_valid }
    end

    context "link set and no edition" do
      let(:link_set) { FactoryGirl.create(:link_set) }
      it { is_expected.to be_valid }
    end

    context "edition and link set" do
      let(:edition) { FactoryGirl.create(:edition) }
      let(:link_set) { FactoryGirl.create(:link_set) }
      it { is_expected.not_to be_valid }
    end
  end
end
