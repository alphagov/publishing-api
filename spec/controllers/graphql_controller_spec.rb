RSpec.describe GraphqlController do
  describe "#live_content" do
    context "when the requested base_path has live content" do
      let(:edition) do
        create(
          :live_edition,
          schema_name: "news_article",
          document_type: "news_story",
          details: {
            "body" => "Some content",
          },
        )
      end

      let(:request_path) { base_path_without_leading_slash(edition.base_path) }

      before do
        get :live_content, params: { base_path: request_path }
      end

      it "returns a 200 OK response" do
        expect(response.status).to eq(200)
      end

      it "returns the content item as JSON data" do
        expect(response.media_type).to eq("application/json")
      end

      it "sets document_type and schema_type as prometheus labels" do
        expect(request.env.dig("govuk.prometheus_labels", "document_type")).to eq(edition.document_type)
        expect(request.env.dig("govuk.prometheus_labels", "schema_name")).to eq(edition.schema_name)
      end

      it "sets cache headers to expire in the default TTL" do
        expect(cache_control["max-age"]).to eq(default_ttl.to_s)
      end

      it "sets a cache-control directive of public" do
        expect(cache_control["public"]).to eq(true)
      end

      context "but the requested route does not match the base_path" do
        let(:edition) do
          create(
            :live_edition,
            base_path: "/base-path",
            document_type: "news_story",
            routes: [
              { path: "/base-path", type: "exact" },
              { path: "/base-path/exact", type: "exact" },
            ],
            schema_name: "news_article",
          )
        end

        let(:request_path) { base_path_without_leading_slash(edition.routes.second[:path]) }

        it "returns a 303 See Other response" do
          expect(response.status).to eq(303)
        end

        it "returns a redirect to the item by base_path" do
          expect(response).to redirect_to("/graphql/content/base-path")
        end
      end
    end

    context "a content item with a non-ASCII base_path" do
      before(:each) do
        create(
          :live_edition,
          base_path: "/news/%D7%91%D7%95%D7%98%20%D7%9C%D7%90%D7%99%D7%A0%D7%93",
          schema_name: "news_article",
        )
        get :live_content, params: { base_path: "news/בוט לאינד" }
      end

      it "returns a 200 OK response" do
        expect(response.status).to eq(200)
      end

      it "returns the presented content item as JSON data" do
        expect(response.media_type).to eq("application/json")
      end
    end

    context "a content item with an invalid path" do
      it "returns a 400 Bad Request response" do
        # we can't run the test with an actual invalid URI so we have to mock that
        expect(Addressable::URI).to receive(:encode).and_wrap_original do |m|
          m.call("/path\nprotocol:")
        end
        get :live_content, params: { base_path: "content/invalid-uri" }
        expect(response.status).to eq(400)
      end
    end

    context "when the requested base_path is not a format supported by GraphQL" do
      let(:edition) do
        create(
          :live_edition,
          schema_name: "get_involved",
        )
      end

      before do
        get :live_content, params: { base_path: base_path_without_leading_slash(edition.base_path) }
      end

      it "returns a 404 not_found response" do
        expect(response.status).to eq(404)
      end
    end

    context "a non-existent content item" do
      before(:each) { get :live_content, params: { base_path: "unknown-content" } }

      it "returns a 404 Not Found response" do
        expect(response.status).to eq(404)
      end

      it "sets cache headers to expire in the default TTL" do
        expect(cache_control["max-age"]).to eq(default_ttl.to_s)
      end

      it "sets a cache-control directive of public" do
        expect(cache_control["public"]).to eq(true)
      end
    end

    context "a gone content item without an explanation and without an alternative_path" do
      let(:edition) do
        create(
          :gone_unpublished_edition_without_explanation,
          schema_name: "news_article",
        )
      end

      before do
        get :live_content, params: { base_path: base_path_without_leading_slash(edition.base_path) }
      end

      it "responds with 410" do
        expect(response.status).to eq(410)
      end

      it "sets cache headers to expire in the default TTL" do
        expect(cache_control["max-age"]).to eq(default_ttl.to_s)
      end

      it "sets a cache-control directive of public" do
        expect(cache_control["public"]).to eq(true)
      end
    end

    context "a gone content item with an explanation and alternative_path" do
      let(:edition) do
        create(
          :gone_unpublished_edition,
          schema_name: "news_article",
        )
      end

      before do
        get :live_content, params: { base_path: base_path_without_leading_slash(edition.base_path) }
      end

      it "responds with 200" do
        expect(response.status).to eq(200)
      end

      it "includes the details" do
        details = JSON.parse(response.body)["details"]
        expect(details["explanation"]).to eq(edition.unpublishing.explanation)
        expect(details["alternative_path"]).to eq(edition.unpublishing.alternative_path)
      end
    end

    it "defers to a service to process the result into a content item" do
      edition = create(:live_edition,
                       schema_name: "news_article",
                       document_type: "news_story",
                       details: {
                         "body" => "Some content",
                       })

      allow_any_instance_of(GraphqlContentItemService)
        .to receive(:process)
        .and_return({ "details" => { "something" => "jason!" } })

      get :live_content, params: {
        base_path: base_path_without_leading_slash(edition.base_path),
      }

      expect(JSON.parse(response.body)).to eq({
        "details" => { "something" => "jason!" },
      })
    end

    it "defers to a service to find the correct edition" do
      expect_any_instance_of(EditionFinderService).to receive(:find)

      get :live_content, params: {
        base_path: base_path_without_leading_slash("/base-path"),
      }
    end

    it "sets cache headers based on the edition's max cache time value" do
      edition = create(
        :live_edition,
        schema_name: "specialist_document",
        details: { max_cache_time: 10 },
      )

      get :live_content, params: { base_path: base_path_without_leading_slash(edition.base_path) }

      expect(cache_control["max-age"]).to eq("10")
    end
  end

  def base_path_without_leading_slash(base_path)
    base_path.gsub(/^\//, "")
  end

  def cache_control
    Rack::Cache::CacheControl.new(response["Cache-Control"])
  end

  def default_ttl
    GraphqlController::DEFAULT_TTL
  end
end
