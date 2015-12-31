require "rails_helper"

RSpec.describe AccessLimit do
  subject { FactoryGirl.build(:access_limit) }

  it "validates that user UIDs are strings" do
    subject.users << "a-string-uuid"
    expect(subject).to be_valid

    subject.users << 123
    expect(subject).not_to be_valid
  end

  context "a content item that is not access limited" do
    let!(:content_item) { create(:draft_content_item) }

    it "is not access limited" do
      expect(AccessLimit.viewable?(content_item)).to be(true)
    end

    it "is viewable by all" do
      expect(AccessLimit.viewable?(content_item, user_uid: "a-user-uid")).to be(true)
    end
  end

  context "an access-limited content item" do
    let!(:content_item) { create(:access_limited_draft_content_item) }
    let(:authorised_user_uid) {
      AccessLimit.find_by(target: content_item).users.first
    }
    let(:unauthorised_user_uid) { "unauthorised-user-uid" }

    it "is access limited" do
      expect(AccessLimit.viewable?(content_item)).to be(false)
    end

    it "is viewable by an authorised user" do
      expect(AccessLimit.viewable?(content_item, user_uid: authorised_user_uid)).to be(true)
    end

    it "is not viewable by an unauthorised user" do
      expect(AccessLimit.viewable?(content_item, user_uid: authorised_user_uid)).to be(true)
      expect(AccessLimit.viewable?(content_item, user_uid: unauthorised_user_uid)).to be(false)
    end
  end
end
