require "rails_helper"

RSpec.describe Queries::GetLatest do
  let(:a) { SecureRandom.uuid }
  let(:b) { SecureRandom.uuid }
  let(:c) { SecureRandom.uuid }

  before do
    FactoryGirl.create(:content_item, content_id: a, user_facing_version: 2, base_path: "/a2", state: "published")
    FactoryGirl.create(:content_item, content_id: a, user_facing_version: 1, base_path: "/a1", state: "superseded")
    FactoryGirl.create(:content_item, content_id: a, user_facing_version: 3, base_path: "/a3")

    FactoryGirl.create(:content_item, content_id: b, user_facing_version: 1, base_path: "/b1", state: "published")
    FactoryGirl.create(:content_item, content_id: b, user_facing_version: 2, locale: "fr", base_path: "/b2", state: "published")

    FactoryGirl.create(:content_item, content_id: c, user_facing_version: 1, base_path: "/c1", state: "published")
    FactoryGirl.create(:content_item, content_id: c, user_facing_version: 2, base_path: "/c2", state: "draft")
  end

  def base_paths(result)
    result.map { |content_item| content_item.base_path }
  end

  it "returns a scope of the latest content_items for the given scope" do
    scope = ContentItem.all
    result = subject.call(scope)
    expect(base_paths(result)).to match_array(["/a3", "/b1", "/b2", "/c2"])

    scope = scope.where(content_id: [a, b])
    result = subject.call(scope)
    expect(base_paths(result)).to match_array(["/a3", "/b1", "/b2"])

    scope = scope.where(locale: 'fr')
    result = subject.call(scope)
    expect(base_paths(result)).to match_array(["/b2"])
  end
end
