require "rails_helper"

RSpec.describe Version do
  subject { FactoryGirl.build(:version) }

  it "starts version numbers on 0" do
    expect(subject.number).to be_zero
  end

  describe "#increment" do
    it "adds one to the number" do
      subject.increment
      expect(subject.number).to eq(1)

      subject.increment
      expect(subject.number).to eq(2)
    end
  end

  describe "#copy_version_from" do
    let(:target) { FactoryGirl.create(:link_set) }

    context "when the target has a version" do
      before do
        FactoryGirl.create(:version, target: target, number: 5)
      end

      it "copies the version number from the target's version" do
        subject.copy_version_from(target)
        expect(subject.number).to eq(5)
      end
    end

    context "when the target does not have a version" do
      it "raises an error" do
        expect {
          subject.copy_version_from(target)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
