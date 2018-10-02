require "rails_helper"

RSpec.describe "GET /v2/content", type: :request do
  let!(:policy_1) {
    create(:edition,
      state: "draft",
      document_type: "policy",
      schema_name: "policy",
      title: "Policy 1",
      base_path: "/cat-rates")
  }

  let!(:policy_2) {
    create(:edition,
      state: "published",
      document_type: "policy",
      schema_name: "policy",
      title: "Policy 2")
  }

  it "responds with a list of content items" do
    expected_result = [
      hash_including(title: "Policy 1"),
      hash_including(title: "Policy 2"),
    ]

    get "/v2/content", params: { fields: %w[title] }
    expect(JSON.parse(response.body, symbolize_names: true)[:results]).to match_array(expected_result)

    get "/v2/content", params: { fields: %w[title] }
    expect(JSON.parse(response.body, symbolize_names: true)[:results]).to match_array(expected_result)
  end

  describe "GET /v2/content" do
    context "when user is signed in" do
      before { login_as_stub_user }

      it "returns a 200" do
        get "/v2/content"
        expect(response.status).to eq(200)
      end
    end

    context "when user is not signed in" do
      around do |spec|
        previous = ENV['GDS_SSO_MOCK_INVALID']
        ENV['GDS_SSO_MOCK_INVALID'] = 'true'
        spec.run
        ENV['GDS_SSO_MOCK_INVALID'] = previous
      end

      # Note: this needs to be separate from the above around block as it has
      # to run after an earlier before block that logs the user in
      before { logout }

      it "returns a 401" do
        get "/v2/content"
        expect(response.status).to eq(401)
      end
    end
  end
end
