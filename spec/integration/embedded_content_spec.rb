RSpec.describe "Embedded documents" do
  include_context "PutContent call"

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
      last_edited_at = "2023-01-01T08:00:00.000Z"
      host_edition = Timecop.freeze Time.zone.parse(last_edited_at) do
        create_live_edition(
          body: "<p>{{embed:content_block_email_address:#{content_block.content_id}}}</p>\n",
          primary_publishing_organisation_uuid: publishing_organisation.content_id,
        )
      end

      statistics_cache = create(:statistics_cache, document: host_edition.document, unique_pageviews: 333)

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
          "last_edited_at" => last_edited_at,
          "unique_pageviews" => statistics_cache.unique_pageviews,
          "instances" => 1,
          "host_content_id" => host_edition.content_id,
          "primary_publishing_organisation" => {
            "content_id" => publishing_organisation.content_id,
            "title" => publishing_organisation.title,
            "base_path" => publishing_organisation.base_path,
          },
        },
      )
    end

    context "when embedded content appears more than once in a field" do
      let!(:host_edition) do
        create_live_edition(
          body: "<p>{{embed:content_block_email_address:#{content_block.content_id}}} {{embed:content_block_email_address:#{content_block.content_id}}}</p>\n",
        )
      end

      it "should return multiple instances" do
        get "/v2/content/#{content_block.content_id}/embedded"
        response_body = parsed_response

        expect(response_body["content_id"]).to eq(content_block.content_id)
        expect(response_body["total"]).to eq(1)

        expect(response_body["results"][0]["instances"]).to eq(2)
      end

      context "when the host edition is changed to reference the content once" do
        before do
          create_live_edition(
            content_id: host_edition.content_id,
            body: "<p>{{embed:content_block_email_address:#{content_block.content_id}}}</p>\n",
          )
        end

        it "should return only one instance" do
          get "/v2/content/#{content_block.content_id}/embedded"
          response_body = parsed_response

          expect(response_body["content_id"]).to eq(content_block.content_id)
          expect(response_body["total"]).to eq(1)

          expect(response_body["results"][0]["instances"]).to eq(1)
        end
      end
    end
  end

  context "pagination" do
    before do
      create_list(:live_edition, 12,
                  links_hash: {
                    embed: [content_block.content_id],
                  })
    end

    it "returns the first page by default" do
      get "/v2/content/#{content_block.content_id}/embedded"
      response_body = parsed_response

      expect(response_body["total"]).to eq(12)
      expect(response_body["total_pages"]).to eq(2)
      expect(response_body["results"].count).to eq(10)
    end

    it "allows the next page to be requested" do
      get "/v2/content/#{content_block.content_id}/embedded?page=2"
      response_body = parsed_response

      expect(response_body["total"]).to eq(12)
      expect(response_body["total_pages"]).to eq(2)
      expect(response_body["results"].count).to eq(2)
    end

    it "allows a per_page argument to be passed" do
      get "/v2/content/#{content_block.content_id}/embedded?per_page=1"
      response_body = parsed_response

      expect(response_body["total"]).to eq(12)
      expect(response_body["total_pages"]).to eq(12)
      expect(response_body["results"].count).to eq(1)
    end
  end

  context "when passing order details" do
    it "orders by title" do
      edition_1 = create(:live_edition,
                         title: "B Title",
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      edition_2 = create(:live_edition,
                         title: "A Title",
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      expect_request_to_order_by(
        order_argument: "title",
        expected_results: [edition_2, edition_1],
      )

      expect_request_to_order_by(
        order_argument: "-title",
        expected_results: [edition_1, edition_2],
      )
    end

    it "orders by document type" do
      edition_1 = create(:live_edition,
                         document_type: "news_article",
                         title: "B",
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      edition_2 = create(:live_edition,
                         document_type: "guide",
                         title: "A",
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      expect_request_to_order_by(
        order_argument: "document_type",
        expected_results: [edition_2, edition_1],
      )

      expect_request_to_order_by(
        order_argument: "-document_type",
        expected_results: [edition_1, edition_2],
      )
    end

    it "orders by unique pageviews" do
      edition_1 = create(:live_edition,
                         title: "B",
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      create(:statistics_cache, document: edition_1.document, unique_pageviews: 999)

      edition_2 = create(:live_edition,
                         title: "A",
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      create(:statistics_cache, document: edition_2.document, unique_pageviews: 1)

      expect_request_to_order_by(
        order_argument: "unique_pageviews",
        expected_results: [edition_2, edition_1],
      )

      expect_request_to_order_by(
        order_argument: "-unique_pageviews",
        expected_results: [edition_1, edition_2],
      )
    end

    it "orders by primary publishing organisation title" do
      edition_1 = create(:live_edition,
                         title: "A",
                         links_hash: {
                           embed: [content_block.content_id],
                           primary_publishing_organisation: [create(:live_edition,
                                                                    title: "B organisation",
                                                                    document_type: "organisation",
                                                                    schema_name: "organisation",
                                                                    base_path: "/government/organisations/b-organisation").content_id],
                         })

      create(:statistics_cache, document: edition_1.document, unique_pageviews: 999)

      edition_2 = create(:live_edition,
                         title: "B",
                         links_hash: {
                           embed: [content_block.content_id],
                           primary_publishing_organisation: [create(:live_edition,
                                                                    title: "A organisation",
                                                                    document_type: "organisation",
                                                                    schema_name: "organisation",
                                                                    base_path: "/government/organisations/a-organisation").content_id],
                         })

      create(:statistics_cache, document: edition_2.document, unique_pageviews: 1)

      expect_request_to_order_by(
        order_argument: "primary_publishing_organisation_title",
        expected_results: [edition_2, edition_1],
      )

      expect_request_to_order_by(
        order_argument: "-primary_publishing_organisation_title",
        expected_results: [edition_1, edition_2],
      )
    end

    it "orders by last edited at" do
      edition_1 = create(:live_edition,
                         title: "B",
                         last_edited_at: Time.zone.now - 1.day,
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      edition_2 = create(:live_edition,
                         title: "A",
                         last_edited_at: Time.zone.now - 5.days,
                         links_hash: {
                           embed: [content_block.content_id],
                         })

      expect_request_to_order_by(
        order_argument: "last_edited_at",
        expected_results: [edition_2, edition_1],
      )

      expect_request_to_order_by(
        order_argument: "-last_edited_at",
        expected_results: [edition_1, edition_2],
      )
    end

    def expect_request_to_order_by(order_argument:, expected_results:)
      get "/v2/content/#{content_block.content_id}/embedded?order=#{order_argument}"
      response_body = parsed_response

      expect(response.status).to eq(200)

      expect(response_body["total"]).to eq(expected_results.count)

      expected_results.each_with_index do |expected_result, i|
        expect(response_body["results"][i]["title"]).to eq(expected_result.title)
      end
    end
  end

private

  def create_live_edition(content_id: SecureRandom.uuid, body: "Some body goes here", primary_publishing_organisation_uuid: nil)
    payload.merge!(
      document_type: "press_release",
      schema_name: "news_article",
      details: { body: },
    )

    if primary_publishing_organisation_uuid.present?
      payload.merge!(
        links: {
          primary_publishing_organisation: [primary_publishing_organisation_uuid],
        },
      )
    end

    put "/v2/content/#{content_id}", params: payload.to_json
    post "/v2/content/#{content_id}/publish", params: {}.to_json

    Document.find_by(content_id:).live
  end
end
