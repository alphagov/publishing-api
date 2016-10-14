require "rails_helper"

RSpec.describe V2::ContentItemsController do
  let(:content_id) { SecureRandom.uuid }

  before do
    stub_request(:any, /content-store/)

    @draft = FactoryGirl.create(
      :draft_content_item,
      content_id: content_id,
      base_path: "/content.en",
      document_type: "topic",
      schema_name: "topic",
      locale: "en",
      user_facing_version: 2,
    )
  end

  describe "index" do
    before do
      @en_draft_content = @draft
      @ar_draft_content = FactoryGirl.create(
        :draft_content_item,
        content_id: content_id,
        locale: "ar",
        base_path: "/content.ar",
        document_type: "topic",
        schema_name: "topic",
        user_facing_version: 2,
      )
      @en_live_content = FactoryGirl.create(
        :live_content_item,
        content_id: content_id,
        locale: "en",
        base_path: "/content.en",
        document_type: "topic",
        schema_name: "topic",
        user_facing_version: 1,
      )
      @ar_live_content = FactoryGirl.create(
        :live_content_item,
        content_id: content_id,
        locale: "ar",
        base_path: "/content.ar",
        document_type: "topic",
        schema_name: "topic",
        user_facing_version: 1,
      )
    end

    context "searching a field" do
      context "when there is a valid query" do
        let(:previous_live_version) do
          FactoryGirl.create(:superseded_content_item,
                             base_path: "/foo",
                             document_type: "topic",
                             schema_name: "topic",
                             title: "zip",
                             user_facing_version: 1)
        end
        let!(:content_item) do
          FactoryGirl.create(:live_content_item,
                             base_path: "/foo",
                             content_id: previous_live_version.content_id,
                             document_type: "topic",
                             schema_name: "topic",
                             title: "bar",
                             user_facing_version: 2)
        end

        it "returns the item when searching for base_path" do
          get :index, params: { document_type: "topic", q: "foo", locale: "all" }
          expect(parsed_response["results"].map { |i| i["base_path"] }).to eq(["/foo"])
        end

        it "returns the item when searching for title" do
          get :index, params: { document_type: "topic", q: "bar", locale: "all" }
          expect(parsed_response["results"].map { |i| i["base_path"] }).to eq(["/foo"])
        end

        it "doesn't return items that are no longer the latest version" do
          get :index, params: { document_type: "topic", q: "zip", fields: %w(title) }
          expect(parsed_response["results"].map { |i| i["title"] }).to eq([])
        end
      end
    end

    context "without providing a locale parameter" do
      before do
        get :index, params: { document_type: "topic", fields: %w(base_path) }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the english content item as json" do
        parsed_response_body = parsed_response["results"]
        expect(parsed_response_body.length).to eq(1)

        base_paths = parsed_response_body.map { |item| item.fetch("base_path") }
        expect(base_paths).to eq ["/content.en"]
      end
    end

    context "providing a specific locale parameter" do
      before do
        get :index, params: { document_type: "topic", fields: %w(base_path), locale: "ar" }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the specific locale content item as json" do
        parsed_response_body = parsed_response["results"]
        expect(parsed_response_body.length).to eq(1)

        base_paths = parsed_response_body.map { |item| item.fetch("base_path") }
        expect(base_paths). to eq ["/content.ar"]
      end
    end

    context "providing a locale parameter set to 'all'" do
      before do
        get :index, params: { document_type: "topic", fields: %w(base_path), locale: "all" }
      end

      let(:parsed_response_body) { parsed_response["results"] }

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has the corrent number of items" do
        expect(parsed_response_body.length).to eq(2)
      end

      it "responds with all the localised content items as json" do
        base_paths = parsed_response_body.map { |item| item.fetch("base_path") }
        expect(base_paths.sort). to eq ["/content.en", "/content.ar"].sort
      end
    end

    context "with pagination params" do
      before do
        get :index, params: { content_format: "topic", fields: ["content_id"], start: "0", page_size: "20" }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end
      it "responds with the content item as json" do
        parsed_response_body = parsed_response["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq(content_id.to_s)
      end
    end

    context "without pagination params" do
      before do
        get :index, params: { content_format: 'topic', fields: ['content_id'] }
      end
      it "is successful" do
        expect(response.status).to eq(200)
      end
      it "responds with the content item as json" do
        parsed_response_body = parsed_response["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq(content_id.to_s)
      end
    end

    context "with all_items param" do
      before do
        get :index, params: { content_format: "topic", fields: ["content_id"], all_items: "true" }
      end
      it "is successful" do
        expect(response.status).to eq(200)
      end
      it "responds with the content item as json" do
        parsed_response_body = parsed_response["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq(content_id.to_s)
      end
    end

    context "with an order param" do
      before do
        @en_draft_content.update!(
          updated_at: Date.new(2016, 1, 1),
          last_edited_at: Date.new(2016, 1, 1),
        )
        @ar_draft_content.update!(
          updated_at: Date.new(2016, 2, 2),
          last_edited_at: Date.new(2016, 2, 2),
        )

        get :index, params: { document_type: "topic", locale: "all", order: order, fields: fields }
      end

      context "when ordering by updated_at ascending" do
        let(:order) { "updated_at" }
        let(:fields) { ["updated_at"] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "updated_at" => "2016-01-01 00:00:00" },
            { "updated_at" => "2016-02-02 00:00:00" },
          ])
        end
      end

      context "when ordering by updated_at descending" do
        let(:order) { "-updated_at" }
        let(:fields) { ["updated_at"] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "updated_at" => "2016-02-02 00:00:00" },
            { "updated_at" => "2016-01-01 00:00:00" },
          ])
        end
      end

      context "when ordering by last_edited_at ascending" do
        let(:order) { "last_edited_at" }
        let(:fields) { ["last_edited_at"] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(response.status).to eq(200), response.body

          expect(results).to eq([
            { "last_edited_at" => "2016-01-01T00:00:00Z" },
            { "last_edited_at" => "2016-02-02T00:00:00Z" },
          ])
        end
      end

      context "when ordering by last_edited_at descending" do
        let(:order) { "-last_edited_at" }
        let(:fields) { ["last_edited_at"] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(response.status).to eq(200), response.body

          expect(results).to eq([
            { "last_edited_at" => "2016-02-02T00:00:00Z" },
            { "last_edited_at" => "2016-01-01T00:00:00Z" },
          ])
        end
      end

      context "when ordering by base_path ascending" do
        let(:order) { "base_path" }
        let(:fields) { ["base_path"] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/content.ar" },
            { "base_path" => "/content.en" },
          ])
        end
      end

      context "when ordering by base_path descending" do
        let(:order) { "-base_path" }
        let(:fields) { ["base_path"] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/content.en" },
            { "base_path" => "/content.ar" },
          ])
        end
      end

      context "when ordering by a field that doesn't exist" do
        let(:order) { "doesnt_exist" }
        let(:fields) { ["content_id"] }

        it "responds with 422 and an error message" do
          expect(response.status).to eq(422)
          message = parsed_response["error"]["message"]
          expect(message).to include(order)
        end
      end

      context "when ordering by a field without an index" do
        let(:order) { "created_at" }
        let(:fields) { ["content_id"] }

        it "responds with 422 and an error message" do
          expect(response.status).to eq(422)
          message = parsed_response["error"]["message"]
          expect(message).to include(order)
        end
      end

      context "ordering by a updated_at when it's not selected" do
        let(:order) { "updated_at" }
        let(:fields) { ["base_path"] }

        it "returns the ordered results" do
          results = parsed_response["results"]

          expect(results).to eq([
            { "base_path" => "/content.en" },
            { "base_path" => "/content.ar" },
          ])
        end
      end
    end

    context "with link filtering params" do
      before do
        org_content_id = SecureRandom.uuid
        link_set = FactoryGirl.create(:link_set, content_id: content_id)
        FactoryGirl.create(:link, link_set: link_set, target_content_id: org_content_id)

        get :index, params: { content_format: "topic", fields: ["content_id"], link_organisations: org_content_id.to_s }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content items for the given organistion as json" do
        parsed_response_body = parsed_response["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq(content_id.to_s)
      end
    end
  end

  describe "show" do
    context "for an existing content item" do
      before do
        get :show, params: { content_id: content_id }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content item as json" do
        parsed_response_body = parsed_response
        expect(parsed_response_body.fetch("content_id")).to eq(content_id.to_s)
      end
    end

    context "for a non-existent content item" do
      it "responds with 404" do
        get :show, params: { content_id: "missing" }

        expect(response.status).to eq(404)
      end
    end
  end

  describe "put_content" do
    context "with valid request params for a new content item" do
      before do
        content_item_hash = @draft.as_json
        content_item_hash = content_item_hash
          .merge("base_path" => "/that-rates")
          .merge("routes" => [{ "path" => "/that-rates", "type" => "exact" }])
        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = content_item_hash.to_json
        put :put_content, params: { content_id: SecureRandom.uuid }
      end

      it "responds with 200" do
        expect(response.status).to eq(200)
      end

      it "responds with the content item" do
        parsed_response_body = parsed_response
        expect(parsed_response_body["base_path"]).to eq("/that-rates")
      end
    end

    context "with valid request params for an existing content item" do
      before do
        content_item_hash = @draft.as_json
        content_item_hash = content_item_hash
          .merge("base_path" => "/that-rates")
          .merge("routes" => [{ "path" => "/that-rates", "type" => "exact" }])

        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = content_item_hash.to_json
        put :put_content, params: { content_id: content_id }
      end

      it "responds with 200" do
        expect(response.status).to eq(200)
      end

      it "responds with the content item" do
        parsed_response_body = parsed_response
        expect(parsed_response_body["content_id"]).to eq(content_id)
      end
    end

    context "with invalid request body" do
      before do
        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = ""
        put :put_content, params: { content_id: content_id }
      end

      it "responds with 400" do
        expect(response.status).to eq(400)
      end
    end
  end

  describe "publish" do
    context "for an existing draft content item" do
      before do
        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = { update_type: "major" }.to_json
        post :publish, params: { content_id: content_id }
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content_id of the published item" do
        parsed_response_body = parsed_response
        expect(parsed_response_body.keys).to include("content_id")
        expect(parsed_response_body["content_id"]).not_to be_nil
      end
    end

    context "for a non-existent content item" do
      it "responds with 404" do
        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = { update_type: "major" }.to_json
        post :publish, params: { content_id: "missing" }

        expect(response.status).to eq(404)
      end
    end
  end

  describe "index" do
    before do
      FactoryGirl.create(:draft_content_item, publishing_app: 'publisher', base_path: '/content')
      FactoryGirl.create(:draft_content_item, publishing_app: 'whitehall', base_path: '/item1')
      FactoryGirl.create(:live_content_item, publishing_app: 'whitehall', base_path: '/item2')
      FactoryGirl.create(:unpublished_content_item, publishing_app: 'specialist_publisher', base_path: '/item3')
    end

    it "displays items filtered by publishing_app parameter" do
      get :index,
        params: {
          document_type: "guide",
          fields: %w(base_path publishing_app),
          publishing_app: "whitehall"
        }
      items = parsed_response["results"]
      expect(items.length).to eq(2)
      expect(items.all? { |i| i["publishing_app"] == "whitehall" }).to be true
    end

    it "filters by state" do
      get :index, params: { document_type: "guide", states: %w(published draft) }

      items = parsed_response["results"]
      draft, published = items.partition { |item| item["publication_state"] == "draft" }

      expect(items.length).to eq(3)
      expect(draft.length).to eq(2)
      expect(published.length).to eq(1)
    end

    it "displays all items by default" do
      get :index, params: { document_type: 'guide', fields: %w(base_path publishing_app) }
      items = parsed_response["results"]
      expect(items.length).to eq(4)
    end
  end
end
