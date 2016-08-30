require "rails_helper"

RSpec.describe Queries::DraftAndLiveVersions do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }

  let(:payload) {
    {
      content_id: content_id,
      base_path: base_path,
      update_type: "major",
      title: "Some Title",
      publishing_app: "publisher",
      rendering_app: "frontend",
      document_type: "guide",
      schema_name: "guide",
      locale: "en",
      routes: [{ path: base_path, type: "exact" }],
      redirects: [],
      phase: "beta",
    }
  }

  before do
    3.times do |i|
      FactoryGirl.create(:content_item,
        state: 'superseded',
        content_id: content_id,
        user_facing_version: i,
        base_path: base_path
      )
    end
    @item = FactoryGirl.create(:live_content_item, :with_draft,
      content_id: content_id,
      user_facing_version: 4,
      draft_version_number: 5,
      base_path: base_path
    )
    FactoryGirl.create(:live_content_item, :with_draft,
      content_id: SecureRandom.uuid,
      lock_version: 2,
      user_facing_version: 5,
    )
  end

  context "when live item is in published state" do
    it "finds the right draft and live versions" do
      result = Queries::DraftAndLiveVersions.call(@item, :user_facing_versions, 'en')
      expect(result["draft"]).to eq(5)
      expect(result["live"]).to eq(4)
    end
  end

  context "when live item is in unpublished state" do
    before do
      State.find_by(content_item: @item).update_column(:name, "unpublished")
    end

    it "finds the right draft and live version" do
      result = Queries::DraftAndLiveVersions.call(@item, :user_facing_versions, 'en')
      expect(result["draft"]).to eq(5)
      expect(result["live"]).to eq(4)
    end
  end
end
