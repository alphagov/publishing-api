RSpec.describe GraphqlController do
  shared_examples "a response with default public cache headers" do
    it "sets cache headers to expire in the default TTL" do
      expect(cache_control["max-age"]).to eq(default_ttl.to_s)
    end

    it "sets a cache-control directive of public" do
      expect(cache_control["public"]).to eq(true)
    end
  end

  shared_examples "a content endpoint with a matching edition" do |content_store|
    let(:edition) { create(edition_factory, **edition_properties) }
    let(:request_path) { base_path_without_leading_slash(edition.base_path) }

    before do
      edition

      get action, params: { base_path: request_path }
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

    it "defers to a service to process the result into a content item" do
      edition = create(edition_factory,
                       schema_name: "news_article",
                       document_type: "news_story",
                       details: { "body" => "Some content" })

      allow_any_instance_of(GraphqlContentItemService)
        .to receive(:process)
        .and_return({ "details" => { "something" => "jason!" } })

      # we have a redundant request in the before block for this example
      get action, params: {
        base_path: base_path_without_leading_slash(edition.base_path),
      }

      expect(JSON.parse(response.body)).to eq({
        "details" => { "something" => "jason!" },
      })
    end

    it_behaves_like "a response with default public cache headers"

    context "when the edition has a max cache time" do
      let(:edition) do
        create(
          edition_factory,
          **edition_properties,
          details: { max_cache_time: 10 },
        )
      end

      it "sets cache headers based on the edition's max cache time value" do
        expect(cache_control["max-age"]).to eq("10")
      end
    end

    context "when the edition has a non-ASCII base_path" do
      let(:edition) do
        create(
          edition_factory,
          **edition_properties,
          base_path: "/news/%D7%91%D7%95%D7%98%20%D7%9C%D7%90%D7%99%D7%A0%D7%93",
        )
      end
      let(:request_path) { "news/בוט לאינד" }

      it "returns a 200 OK response" do
        expect(response.status).to eq(200)
      end

      it "returns the presented content item as JSON data" do
        expect(response.media_type).to eq("application/json")
      end
    end

    context "when the requested route does not match the base_path" do
      let(:edition) do
        create(
          edition_factory,
          **edition_properties,
          base_path: "/base-path",
          routes: [
            { path: "/base-path", type: "exact" },
            { path: "/base-path/exact", type: "exact" },
          ],
        )
      end
      let(:request_path) { base_path_without_leading_slash(edition.routes.second[:path]) }

      it "returns a 303 See Other response" do
        expect(response.status).to eq(303)
      end

      it "returns a redirect to the item by base_path" do
        redirect_path = case action
                        when :draft_content
                          "/graphql/draft/base-path"
                        when :live_content
                          "/graphql/content/base-path"
                        end

        expect(response).to redirect_to(redirect_path)
      end

      it_behaves_like "a response with default public cache headers"
    end

    context "when the edition is of a schema unsupported by GraphQL" do
      let(:edition) { create(edition_factory, schema_name: "get_involved") }

      it "returns a 404 Not Found response" do
        expect(response.status).to eq(404)
      end

      it_behaves_like "a response with default public cache headers"
    end

    if content_store == :live
      context "when the edition is gone without an explanation or alternative_path" do
        let(:edition) do
          create(
            :gone_unpublished_edition_without_explanation,
            schema_name: "news_article",
          )
        end

        it "responds with 410" do
          expect(response.status).to eq(410)
        end

        it_behaves_like "a response with default public cache headers"
      end

      context "when the edition is gone with an explanation and alternative_path" do
        let(:edition) do
          create(
            :gone_unpublished_edition,
            schema_name: "news_article",
          )
        end

        it "responds with 200" do
          expect(response.status).to eq(200)
        end

        it "includes the details" do
          details = JSON.parse(response.body)["details"]
          expect(details["explanation"]).to eq(edition.unpublishing.explanation)
          expect(details["alternative_path"]).to eq(edition.unpublishing.alternative_path)
        end

        it_behaves_like "a response with default public cache headers"
      end
    end
  end

  shared_examples "a content endpoint" do
    it "defers to a service to find the correct edition" do
      expect_any_instance_of(EditionFinderService).to receive(:find)

      get :live_content, params: {
        base_path: base_path_without_leading_slash("/base-path"),
      }
    end

    context "when there's no matching edition" do
      before(:each) { get action, params: { base_path: "unknown-content" } }

      it "returns a 404 Not Found response" do
        expect(response.status).to eq(404)
      end

      it_behaves_like "a response with default public cache headers"
    end

    context "when the requested base path is invalid" do
      it "returns a 400 Bad Request response" do
        # we can't run the test with an actual invalid URI so we have to mock that
        expect(Addressable::URI).to receive(:encode).and_wrap_original do |m|
          m.call("/path\nprotocol:")
        end
        get action, params: { base_path: "content/invalid-uri" }
        expect(response.status).to eq(400)
      end
    end
  end

  describe "#draft_content" do
    let(:action) { :draft_content }

    context "when unpermitted to access draft content via GraphQL" do
      before { Rails.application.config.permit_graphql_draft_content_access = false }

      it "responds with a 401 even with matching content" do
        base_path = "/world"
        edition_properties = {
          base_path:,
          schema_name: "world_index",
          document_type: "world_index",
          details: { "body" => "some content" },
        }
        create(:draft_edition, **edition_properties)
        create(:live_edition, **edition_properties)
        request_path = base_path_without_leading_slash(base_path)

        get action, params: { base_path: request_path }

        expect(response.status).to eq(401)
      end
    end

    context "when permitted to access draft content via GraphQL" do
      before { Rails.application.config.permit_graphql_draft_content_access = true }

      it "can respond with a 200" do
        base_path = "/world"
        edition_properties = {
          base_path:,
          schema_name: "world_index",
          document_type: "world_index",
          details: { "body" => "some content" },
        }
        create(:draft_edition, **edition_properties)
        create(:live_edition, **edition_properties)
        request_path = base_path_without_leading_slash(base_path)

        get action, params: { base_path: request_path }

        expect(response.status).to eq(200)
      end

      it_behaves_like "a content endpoint"

      context "when the requested base_path has draft content" do
        let(:edition_factory) { :draft_edition }
        let(:edition_properties) do
          {
            schema_name: "person",
            document_type: "person",
            details: { "body" => "Some content" },
          }
        end

        it_behaves_like "a content endpoint with a matching edition", :draft
      end

      context "when the requested base_path only has live content" do
        let(:edition_factory) { :live_edition }
        let(:edition_properties) do
          {
            schema_name: "news_article",
            document_type: "news_story",
            details: { "body" => "Some content" },
          }
        end

        it_behaves_like "a content endpoint with a matching edition", :live
      end
    end
  end

  describe "#live_content" do
    let(:action) { :live_content }

    it_behaves_like "a content endpoint"

    context "when the requested base_path has live content" do
      let(:edition_factory) { :live_edition }
      let(:edition_properties) do
        {
          schema_name: "news_article",
          document_type: "news_story",
          details: { "body" => "Some content" },
        }
      end

      it_behaves_like "a content endpoint with a matching edition", :live
    end

    context "when the requested base_path only has draft content" do
      let(:edition) do
        create(
          :draft_edition,
          schema_name: "person",
          document_type: "person",
          details: {
            "body" => "Some content",
          },
        )
      end

      let(:request_path) { base_path_without_leading_slash(edition.base_path) }

      before do
        get :live_content, params: { base_path: request_path }
      end

      it "returns a 404 Not Found response" do
        expect(response.status).to eq(404)
      end

      it "doesn't return any content item data" do
        expect(response.body).not_to be_present
      end
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
