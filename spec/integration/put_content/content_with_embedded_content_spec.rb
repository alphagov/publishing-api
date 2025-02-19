RSpec.describe "PUT /v2/content when embedded content is provided" do
  include_context "PutContent call"

  context "with embedded content as a string" do
    let(:first_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact", details: { email: "foo@example.com", phone: "123456" }) }
    let(:second_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document, content_id:) }
    let(:first_embed_code) { "{{embed:contact:#{first_contact.document.content_id}}}" }
    let(:second_embed_code) { "{{embed:contact:#{second_contact.document.content_id}}}" }

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

    it "should send transformed content to the content store" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect_content_store_to_have_received_details_including({ "body" => "#{presented_details_for(first_contact, first_embed_code)} #{presented_details_for(second_contact, second_embed_code)}" })
    end

    context "when fields are referenced" do
      let(:first_embed_code) { "{{embed:contact:#{first_contact.document.content_id}/email}}" }
      let(:second_embed_code) { "{{embed:contact:#{first_contact.document.content_id}/phone}}" }

      let(:body) do
        "
        Hello, here is some an email:

        #{first_embed_code}

        And here is a phone number:

        #{second_embed_code}
        "
      end

      let(:expected_body) do
        "
        Hello, here is some an email:

        #{presented_details_for(first_contact, first_embed_code)}

        And here is a phone number:

        #{presented_details_for(first_contact, second_embed_code)}
        "
      end

      before do
        payload.merge!(details: { body: })
      end

      it "should send transformed content to the content store" do
        put "/v2/content/#{content_id}", params: payload.to_json

        expect_content_store_to_have_received_details_including({ "body" => expected_body })
      end
    end
  end

  context "when embedded content is in a details field other than body" do
    let(:first_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:second_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:document) { create(:document, content_id:) }

    let(:first_embed_code) { "{{embed:contact:#{first_contact.document.content_id}}}" }

    let(:payload_for_multiple_field_embeds) do
      payload.merge!(
        document_type: "transaction",
        schema_name: "transaction",
        details: {
          downtime_message: "{{embed:contact:#{first_contact.document.content_id}}}",
        },
      )
    end

    it "should create a link" do
      expect {
        put "/v2/content/#{content_id}", params: payload_for_multiple_field_embeds.to_json
      }.to change(Link, :count).by(1)

      expect(Link.find_by(target_content_id: first_contact.content_id)).not_to be_nil
    end

    it "should send transformed content to the content store" do
      put "/v2/content/#{content_id}", params: payload_for_multiple_field_embeds.to_json

      expect_content_store_to_have_received_details_including({ "downtime_message" => presented_details_for(first_contact, first_embed_code) })
    end
  end

  context "with multipart content" do
    let(:first_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:second_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:first_embed_code) { "{{embed:contact:#{first_contact.document.content_id}}}" }
    let(:second_embed_code) { "{{embed:contact:#{second_contact.document.content_id}}}" }
    let(:document) { create(:document, content_id:) }
    let(:details) do
      {
        country: {
          slug: "some-country",
          name: "Some country",
        },
        updated_at: "2015-10-15T11:00:20+01:00",
        reviewed_at: "2015-10-15T11:00:20+01:00",
        change_description: "Latest Update - this advice has been reviewed and re-issued without amendment",
        alert_status: [],
        email_signup_link: "/foreign-travel-advice/email-signup",
        parts: [
          {
            slug: "part-1",
            title: "Part 1",
            body: [
              {
                "content_type": "text/govspeak",
                "content": first_embed_code,
              },
              {
                "content_type": "text/html",
                "content": "<p>#{first_embed_code}</p>",
              },
            ],
          },
          {
            slug: "part-2",
            title: "Part 2",
            body: [
              {
                "content_type": "text/govspeak",
                "content": second_embed_code,
              },
              {
                "content_type": "text/html",
                "content": "<p>#{second_embed_code}</p>",
              },
            ],
          },
        ],
      }
    end

    before do
      payload.merge!(document_type: "travel_advice", schema_name: "travel_advice", details:)
    end

    it "should create links" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(4)

      expect(Link.find_by(target_content_id: first_contact.content_id)).not_to be_nil
      expect(Link.find_by(target_content_id: second_contact.content_id)).not_to be_nil
    end

    it "should send transformed content to the content store" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect_content_store_to_have_received_details_including({
        "parts" => [
          {
            "slug" => "part-1",
            "title" => "Part 1",
            "body" => [
              {
                "content_type" => "text/govspeak",
                "content" => presented_details_for(first_contact, first_embed_code),
              },
              {
                "content_type" => "text/html",
                "content" => "<p>#{presented_details_for(first_contact, first_embed_code)}</p>",
              },
            ],
          },
          {
            "slug" => "part-2",
            "title" => "Part 2",
            "body" => [
              {
                "content_type" => "text/govspeak",
                "content" => presented_details_for(second_contact, second_embed_code),
              },
              {
                "content_type" => "text/html",
                "content" => "<p>#{presented_details_for(second_contact, second_embed_code)}</p>",
              },
            ],
          },
        ],
      })
    end
  end

  context "with embedded content as an array" do
    let(:first_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:second_contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:first_embed_code) { "{{embed:contact:#{first_contact.document.content_id}}}" }
    let(:second_embed_code) { "{{embed:contact:#{second_contact.document.content_id}}}" }
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

    it "should send transformed content to the content store" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect_content_store_to_have_received_details_including({ "body" => array_including({ "content_type" => "text/govspeak", "content" => "#{presented_details_for(first_contact, first_embed_code)} #{presented_details_for(second_contact, second_embed_code)}" }) })
    end
  end

  context "with mixed embedded content" do
    let(:email_address) { create(:edition, state: "published", content_store: "live", document_type: "content_block_email_address", details: { email_address: "foo@example.com" }) }
    let(:email_embed_code) { "{{embed:content_block_email_address:#{email_address.document.content_id}}}" }
    let(:contact) { create(:edition, state: "published", content_store: "live", document_type: "contact") }
    let(:contact_embed_code) { "{{embed:contact:#{contact.document.content_id}}}" }
    let(:document) { create(:document, content_id:) }

    before do
      payload.merge!(document_type: "press_release", schema_name: "news_article", details: { body: "#{email_embed_code} #{contact_embed_code}" })
    end

    it "should create links" do
      expect {
        put "/v2/content/#{content_id}", params: payload.to_json
      }.to change(Link, :count).by(2)

      expect(Link.find_by(target_content_id: contact.content_id)).not_to be_nil
      expect(Link.find_by(target_content_id: email_address.content_id)).not_to be_nil
    end

    it "should send transformed content to the content store" do
      put "/v2/content/#{content_id}", params: payload.to_json

      expect_content_store_to_have_received_details_including({ "body" => "#{presented_details_for(email_address, email_embed_code)} #{presented_details_for(contact, contact_embed_code)}" })
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

private

  def expect_content_store_to_have_received_details_including(expected_payload)
    assert_requested :put,
                     Plek.find("draft-content-store") + "/content#{base_path}",
                     body: hash_including({ "details" => hash_including(expected_payload) })
  end
end
