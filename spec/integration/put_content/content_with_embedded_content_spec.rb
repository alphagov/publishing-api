RSpec.describe "PUT /v2/content when embedded content is provided" do
  include_context "PutContent call"

  context "with embedded content" do
    let(:contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document) }
    let!(:link) { document.content_id }

    before do
      payload.merge!(document_type: "press_release", schema_name: "news_article", details: { body: "{{embed:contact:#{contact.document.content_id}}}" })
    end

    it "should create links" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(1)

      expect(Link.find_by(target_content_id: contact.content_id)).to be
    end
  end
end
