RSpec.describe "PUT /v2/content when embedded content is provided" do
  include_context "PutContent call"

  context "with embedded content as a string" do
    let(:first_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:second_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document, content_id:) }

    before do
      payload.merge!(document_type: "press_release", schema_name: "news_article", details: { body: "{{embed:contact:#{first_contact.document.content_id}}} {{embed:contact:#{second_contact.document.content_id}}}" })
    end

    it "should create links" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(2)

      expect(Link.find_by(target_content_id: first_contact.content_id)).not_to be_nil
      expect(Link.find_by(target_content_id: second_contact.content_id)).not_to be_nil
    end
  end

  context "with embedded content as an array" do
    let(:first_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:second_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document, content_id:) }

    before do
      payload.merge!(document_type: "person", schema_name: "person", details: { body: [{ content_type: "text/govspeak", content: "{{embed:contact:#{first_contact.document.content_id}}} {{embed:contact:#{second_contact.document.content_id}}}" }] })
    end

    it "should create links" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(2)

      expect(Link.find_by(target_content_id: first_contact.content_id)).not_to be_nil
      expect(Link.find_by(target_content_id: second_contact.content_id)).not_to be_nil
    end
  end

  context "without embedded content and embed links already existing on a draft edition" do
    let(:contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document, content_id:) }
    let(:edition) { create(:edition, document:) }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
      edition.links.create!({
        link_type: "embed",
        target_content_id: contact.content_id,
        position: 0,
      })
      payload.merge!(document_type: "press_release", schema_name: "news_article", details: { body: "no embed links" })
    end

    it "should remove embed links" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(-1)

      expect(Link.find_by(target_content_id: contact.content_id)).to be_nil
    end
  end

  context "with different embedded content and embed links already existing on a draft edition" do
    let(:first_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:second_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document, content_id:) }
    let(:edition) { create(:edition, document:) }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
      edition.links.create!({
        link_type: "embed",
        target_content_id: first_contact.content_id,
        position: 0,
      })
      payload.merge!(document_type: "press_release", schema_name: "news_article", details: { body: "{{embed:contact:#{second_contact.document.content_id}}}" })
    end

    it "should replace the embed link" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(0)

      expect(Link.find_by(target_content_id: first_contact.content_id)).to be_nil
      expect(Link.find_by(target_content_id: second_contact.content_id)).not_to be_nil
    end
  end

  context "with embedded content that does not exist" do
    let(:document) { create(:document, content_id:) }
    let(:fake_content_id) { SecureRandom.uuid }

    before do
      payload.merge!(document_type: "press_release", schema_name: "news_article", details: { body: "{{embed:contact:#{fake_content_id}}}" })
    end

    it "should return a 422 error" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect(response).to be_unprocessable
      expect(response.body).to match(/Could not find any live editions in locale en for: #{fake_content_id}/)
    end
  end

  context "with a mixture of embedded content that does and does not exist" do
    let(:contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document, content_id:) }
    let(:first_fake_content_id) { SecureRandom.uuid }
    let(:second_fake_content_id) { SecureRandom.uuid }

    before do
      payload.merge!(document_type: "press_release", schema_name: "news_article", details: { body: "{{embed:contact:#{contact.document.content_id}}} {{embed:contact:#{first_fake_content_id}}} {{embed:contact:#{second_fake_content_id}}}" })
    end

    it "should return a 422 error" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect(response).to be_unprocessable
      expect(response.body).to match(/Could not find any live editions in locale en for: #{first_fake_content_id}, #{second_fake_content_id}/)
    end
  end
end
