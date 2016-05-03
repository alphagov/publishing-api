require "rails_helper"

RSpec.describe Unpublishing do
  describe "validations" do
    subject { FactoryGirl.build(:unpublishing) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end

    it "requires a type" do
      subject.type = nil
      expect(subject).to be_invalid
      expect(subject.errors[:type].size).to eq(1)
    end

    it "does not require an explanation for a 'gone'" do
      subject.type = "gone"
      subject.explanation = nil
      expect(subject).to be_valid
    end

    it "requires an explanation for a 'withdrawal'" do
      subject.type = "withdrawal"
      subject.explanation = nil
      expect(subject).to be_invalid
      expect(subject.errors[:explanation].size).to eq(1)
    end

    it "does not require an alternative_url for a 'gone'" do
      subject.type = "gone"
      subject.alternative_url = nil
      expect(subject).to be_valid
    end

    it "requires an alternative_url for a 'redirect'" do
      subject.type = "redirect"
      subject.alternative_url = nil
      expect(subject).to be_invalid
      expect(subject.errors[:alternative_url].size).to eq(1)
    end
  end
end
