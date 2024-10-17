RSpec.describe "Embedded documents" do
  let!(:publishing_organisation) do
    create(:live_edition,
           title: "bar",
           document_type: "organisation",
           schema_name: "organisation",
           base_path: "/government/organisations/bar")
  end

  let!(:content_block) do
    create(:live_edition,
           title: "Foo's email address",
           document_type: "content_block_email_address",
           schema_name: "content_block_email_address",
           details: {
             "email_address" => "foo@example.com",
           })
  end

  context "when the target edition doesn't exist" do
    it "returns a 404" do
      get "/v2/content/#{SecureRandom.uuid}/embedded"

      expect(response.status).to eq(404)
    end
  end

  context "when no editions embed the content block" do
    it "returns an empty results array" do
      unembedded_edition = create(:live_edition)

      get "/v2/content/#{unembedded_edition.content_id}/embedded"

      expect(response.status).to eq(200)
      response_body = parsed_response

      expect(response_body["content_id"]).to eq(unembedded_edition.content_id)
      expect(response_body["total"]).to eq(0)
      expect(response_body["results"]).to eq([])
    end
  end

  context "when an edition embeds a reference to the content block" do
    it "returns details of the edition and its publishing organisation in the results" do
      host_edition = create(:live_edition,
                            publishing_app: "whitehall",
                            details: {
                              "body" => "<p>{{embed:email_address:#{content_block.content_id}}}</p>\n",
                            },
                            links_hash: {
                              primary_publishing_organisation: [publishing_organisation.content_id],
                              embed: [content_block.content_id],
                            })

      get "/v2/content/#{content_block.content_id}/embedded"

      expect(response.status).to eq(200)

      response_body = parsed_response

      expect(response_body["content_id"]).to eq(content_block.content_id)
      expect(response_body["total"]).to eq(1)
      expect(response_body["results"]).to include(
        {
          "title" => host_edition.title,
          "base_path" => host_edition.base_path,
          "document_type" => host_edition.document_type,
          "publishing_app" => host_edition.publishing_app,
          "last_edited_by_editor_id" => host_edition.last_edited_by_editor_id,
          "primary_publishing_organisation" => {
            "content_id" => publishing_organisation.content_id,
            "title" => publishing_organisation.title,
            "base_path" => publishing_organisation.base_path,
          },
        },
      )
    end
  end
end
