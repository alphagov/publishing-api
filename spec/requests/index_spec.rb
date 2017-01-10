require "rails_helper"

RSpec.describe "GET /v2/content", type: :request do
  let!(:policy_1) {
    FactoryGirl.create(:edition,
      state: "draft",
      document_type: "policy",
      schema_name: "policy",
      title: "Policy 1",
      base_path: "/cat-rates",
    )
  }

  let!(:policy_2) {
    FactoryGirl.create(:edition,
      state: "published",
      document_type: "policy",
      schema_name: "policy",
      title: "Policy 2",
    )
  }

  it "accepts either 'content_format' or 'document_type'" do
    expected_result = [
      hash_including(title: "Policy 1"),
      hash_including(title: "Policy 2"),
    ]

    get "/v2/content", params: { document_type: "policy", fields: ["title"] }
    expect(JSON.parse(response.body, symbolize_names: true)[:results]).to match_array(expected_result)

    get "/v2/content", params: { content_format: "policy", fields: ["title"] }
    expect(JSON.parse(response.body, symbolize_names: true)[:results]).to match_array(expected_result)
  end

  context "without a format" do
    it "422s" do
      get "/v2/content", params: { fields: ["title"] }

      expect(response.status).to eq(422)
    end
  end
end
