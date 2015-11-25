require "rails_helper"

RSpec.describe Version do
  subject { FactoryGirl.build(:version) }

  describe "validations" do
    describe "version comparison between draft and live" do
      let!(:live_content_item) { FactoryGirl.create(:live_content_item, :with_draft) }
      let!(:live_version) { FactoryGirl.create(:version, target: live_content_item, number: 5) }

      let(:draft_content_item) { live_content_item.draft_content_item }
      let(:draft_version) { FactoryGirl.create(:version, target: draft_content_item, number: 5) }

      it "is invalid if the draft version is less than the live version" do
        draft_version.number = 4
        expect(draft_version).to be_invalid
      end

      it "is invalid if the draft version is equal to the live version" do
        draft_version.number = 5
        expect(draft_version).to be_invalid
      end

      it "is valid if the draft version is greater than the live version" do
        draft_version.number = 6
        expect(draft_version).to be_valid
      end

      context "when there is no draft content item or version" do
        let!(:live_content_item) { FactoryGirl.create(:live_content_item) }
        let!(:live_version) { FactoryGirl.create(:version, target: live_content_item, number: 5) }

        it "is valid" do
          live_version.number = 123
          expect(live_version).to be_valid
        end
      end
    end

    it "requires that the version number be higher than its predecessor" do
      item = FactoryGirl.create(:draft_content_item)
      subject.update!(target: item, number: 5)

      subject.number = 4
      expect(subject).to be_invalid

      subject.number = 5
      expect(subject).to be_invalid
    end
  end

  it "starts version numbers on 0" do
    expect(subject.number).to be_zero
    expect(subject).to be_valid
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

  describe "#conflicts_with?(previous_version_number)" do
    before do
      subject.number = 2
    end

    context "when the previous version is lower than the current version" do
      let(:previous_version_number) { subject.number - 1 }

      it "conflicts" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(true)
      end
    end

    context "when the previous version matches the current version number" do
      let(:previous_version_number) { subject.number }

      it "does not conflict" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(false)
      end
    end

    context "when the previous version is larger than the current version number" do
      let(:previous_version_number) { subject.number + 1 }

      it "conflicts, and something really weird is going on" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(true)
      end
    end

    context "when the previous version is absent" do
      let(:previous_version_number) { nil }

      it "does not conflict" do
        expect(subject.conflicts_with?(previous_version_number)).to eq(false)
      end
    end
  end
end
