require "rails_helper"

RSpec.describe "Paging through content items" do
  before do
    5.times do |n|
      FactoryGirl.create(
        :draft_content_item,
        base_path: "/content-#{n}",
        format: "guide",
        public_updated_at: n.minutes.ago
      )
    end
  end

  context "when no pagination params are supplied" do
    before do
      get "/v2/content", content_format: "guide", fields: %w(base_path publishing_app)
    end

    it "responds successfully" do
      expect(response).to be_successful
    end

    it "responds with content items in the correct order" do
      parsed_response_body = JSON.parse(response.body)
      expect(parsed_response_body.size).to eq(5)
      expect(parsed_response_body.first["base_path"]).to eq("/content-0")
      expect(parsed_response_body.last["base_path"]).to eq("/content-4")
    end
  end

  context "when pagination params are supplied" do
    before do
      get "/v2/content",
        content_format: "guide",
        fields: %w(base_path publishing_app),
        start: "3",
        page_size: "2"
    end

    it "responds successfully" do
      expect(response).to be_successful
    end

    it "responds with content items limited by page_size" do
      parsed_response_body = JSON.parse(response.body)
      expect(parsed_response_body.size).to eq(2)
      expect(parsed_response_body.first["base_path"]).to eq("/content-3")
      expect(parsed_response_body.last["base_path"]).to eq("/content-4")
    end
  end
end
