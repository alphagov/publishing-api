require "rails_helper"

RSpec.describe "GET /v2/linkables", type: :request do
  let!(:policy_1) {
    create(:edition,
      state: "draft",
      document_type: "policy",
      title: "Policy 1",
      base_path: "/cat-rates",
      details: {
        internal_name: "Cat rates (do not use for actual cats)"
      })
  }

  let!(:policy_2) {
    create(:edition,
      state: "published",
      document_type: "policy",
      title: "Policy 2",
      base_path: "/vat-rates")
  }

  around do |example|
    Sidekiq::Testing.disable! do
      example.run
    end
  end

  it "returns the title, content ID, state, internal name and base path for all editions of a given format" do
    get "/v2/linkables", params: { document_type: "policy" }

    expect(JSON.parse(response.body, symbolize_names: true)).to match_array([
      hash_including(
        content_id: policy_1.document.content_id,
        title: "Policy 1",
        publication_state: "draft",
        base_path: "/cat-rates",
        internal_name: "Cat rates (do not use for actual cats)",
      ),
      hash_including(
        content_id: policy_2.document.content_id,
        title: "Policy 2",
        publication_state: "published",
        base_path: "/vat-rates",
        internal_name: "Policy 2"
      ),
    ])
  end

  context "without a format" do
    it "422s" do
      get "/v2/linkables"

      expect(response.status).to eq(422)
    end
  end
end
