require "rails_helper"

RSpec.describe "Paging through editions" do
  before do
    5.times do |n|
      create(
        :draft_edition,
        base_path: "/content-#{n}",
        document_type: "nonexistent-schema",
        schema_name: "nonexistent-schema",
        public_updated_at: n.minutes.ago,
      )
    end
  end

  context "when no pagination params are supplied" do
    before do
      get "/v2/content", params: { content_format: "nonexistent-schema", fields: %w[base_path publishing_app] }
    end

    it "responds successfully" do
      expect(response).to be_successful
    end

    it "responds with editions in the correct order" do
      parsed_response_body = parsed_response["results"]
      expect(parsed_response_body.size).to eq(5)
      expect(parsed_response_body.first["base_path"]).to eq("/content-0")
      expect(parsed_response_body.last["base_path"]).to eq("/content-4")
    end
  end

  context "when pagination params are supplied" do
    before do
      get "/v2/content",
          params: {
            content_format: "nonexistent-schema",
            fields: %w[base_path publishing_app],
            offset: "3",
            per_page: "2",
          }
    end

    it "responds successfully" do
      expect(response).to be_successful
    end

    it "responds with editions limited by page_size" do
      parsed_response_body = parsed_response["results"]
      expect(parsed_response_body.size).to eq(2)
      expect(parsed_response_body.first["base_path"]).to eq("/content-3")
      expect(parsed_response_body.last["base_path"]).to eq("/content-4")
    end
  end
end
