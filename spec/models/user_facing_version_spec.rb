require "rails_helper"

RSpec.describe UserFacingVersion do
  subject { FactoryGirl.build(:user_facing_version) }

  it "starts version numbers at 0" do
    content_item = FactoryGirl.create(:content_item)
    user_facing_version = UserFacingVersion.create(content_item: content_item)

    expect(user_facing_version.number).to be_zero
    expect(user_facing_version).to be_valid
  end

  describe "#increment" do
    it "adds one to the number" do
      subject.increment
      expect(subject.number).to eq(2)

      subject.increment
      expect(subject.number).to eq(3)
    end
  end
end
