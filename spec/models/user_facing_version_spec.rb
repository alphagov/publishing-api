require "rails_helper"

RSpec.describe UserFacingVersion do
  describe ".latest" do
    before do
      FactoryGirl.create(:content_item, user_facing_version: 2, title: "Latest")
      FactoryGirl.create(:content_item, user_facing_version: 1)
    end

    it "returns the content item with the latest user_facing version" do
      item = described_class.latest(ContentItem.all)
      expect(item.title).to eq("Latest")
    end
  end
end
