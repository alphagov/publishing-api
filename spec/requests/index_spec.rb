require "rails_helper"

RSpec.describe "GET /v2/content", type: :request do
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

  it "accepts either 'content_format' or 'document_type'" do
    expected_result = [
      hash_including(title: "Policy 1"),
      hash_including(title: "Policy 2"),
    ]

    get "/v2/content", document_type: "policy", fields: ["title"]
    expect(JSON.parse(response.body, symbolize_names: true)).to match_array(expected_result)

    get "/v2/content", content_format: "policy", fields: ["title"]
    expect(JSON.parse(response.body, symbolize_names: true)).to match_array(expected_result)
  end

  context "without a format" do
    it "422s" do
      get "/v2/content", fields: ["title"]

      expect(response.status).to eq(422)
    end
  end
end
