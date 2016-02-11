require "rails_helper"

RSpec.describe SemanticVersion do
  describe ".latest" do
    before do
      FactoryGirl.create(
        :content_item,
        :with_semantic_version,
        semantic_version: 2,
        title: "Latest",
      )

      FactoryGirl.create(
        :content_item,
        :with_semantic_version,
        semantic_version: 1,
      )
    end

    it "returns the content item with the latest semantic lock_version" do
      item = described_class.latest(ContentItem.all)
      expect(item.title).to eq("Latest")
    end
  end
end
