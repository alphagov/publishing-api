require "rails_helper"

RSpec.describe LockVersion do
  subject do
    content_item = FactoryGirl.create(:content_item)
    FactoryGirl.build(:lock_version, target: content_item)
  end

  it "starts version numbers at 0" do
    content_item = FactoryGirl.create(:content_item)
    lock_version = LockVersion.create!(target: content_item)
    expect(lock_version.number).to be_zero
    expect(lock_version).to be_valid
  end

  describe "#conflicts_with?(previous_version_number)" do
    before do
      subject.number = 2
    end

    context "when the previous lock_version is lower than the current lock_version" do
      let(:previous_version_number) { subject.number - 1 }

      it "conflicts" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(true)
      end
    end

    context "when the previous lock_version matches the current lock_version number" do
      let(:previous_version_number) { subject.number }

      it "does not conflict" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(false)
      end
    end

    context "when the previous lock_version is larger than the current lock_version number" do
      let(:previous_version_number) { subject.number + 1 }

      it "conflicts, and something really weird is going on" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(true)
      end
    end

    context "when the previous lock_version is absent" do
      let(:previous_version_number) { nil }

      it "does not conflict" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(false)
      end
    end
  end

  describe "#increment" do
    it "adds one to the number" do
      subject.increment
      expect(subject.number).to eq(1)

      expect(subject.lock_version_target.stale_lock_version).to eq(1)

      subject.increment
      expect(subject.number).to eq(2)

      subject.save

      expect(subject.lock_version_target.stale_lock_version).to eq(2)
    end
  end
end
