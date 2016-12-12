require "rails_helper"

RSpec.describe Location do
  describe "validations" do
    subject { FactoryGirl.build(:location) }

    it "is valid for the default factory" do
      expect(subject).to be_valid
    end
  end
end
