require "rails_helper"

RSpec.describe "GET /v2/linkables", type: :request do
  let!(:policy_1) {
    FactoryGirl.create(:content_item,
      state: "draft",
      format: "policy",
      title: "Policy 1",
      base_path: "/cat-rates",
    )
  }

  let!(:policy_2) {
    FactoryGirl.create(:content_item,
      state: "published",
      format: "policy",
      title: "Policy 2",
    )
  }

  it "returns the title, content ID, state, and base path for all content items of a given format" do
    get "/v2/linkables", format: "policy"

    expect(JSON.parse(response.body, symbolize_names: true)).to match_array([
      {
        content_id: policy_1.content_id,
        title: "Policy 1",
        publication_state: "draft",
        base_path: "/cat-rates",
      },
      {
        content_id: policy_2.content_id,
        title: "Policy 2",
        publication_state: "live",
        base_path: "/vat-rates",
      },
    ])
  end

  context "without a format" do
    it "422s" do
      get "/v2/linkables"

      expect(response.status).to eq(422)
    end
  end
end
