require "rails_helper"

RSpec.describe "GET /v2/content", type: :request do
  let!(:policy_1) {
    create(:edition,
      state: "draft",
      document_type: "policy",
      schema_name: "policy",
      title: "Policy 1",
      base_path: "/cat-rates",
    )
  }

  let!(:policy_2) {
    create(:edition,
      state: "published",
      document_type: "policy",
      schema_name: "policy",
      title: "Policy 2",
    )
  }

  it "responds with a list of content items" do
    expected_result = [
      hash_including(title: "Policy 1"),
      hash_including(title: "Policy 2"),
    ]

    get "/v2/content", params: { fields: ["title"] }
    expect(JSON.parse(response.body, symbolize_names: true)[:results]).to match_array(expected_result)

    get "/v2/content", params: { fields: ["title"] }
    expect(JSON.parse(response.body, symbolize_names: true)[:results]).to match_array(expected_result)
  end
end
