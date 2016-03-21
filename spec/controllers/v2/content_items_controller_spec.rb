require "rails_helper"

RSpec.describe V2::ContentItemsController do
  let(:content_id) { SecureRandom.uuid }

  before do
    stub_request(:any, /content-store/)

    @draft = FactoryGirl.create(
      :draft_content_item,
      content_id: content_id,
      base_path: "/content.en",
      format: "topic",
      locale: "en",
      lock_version: 2,
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
        format: "topic",
        lock_version: 2,
      )
      @en_live_content = FactoryGirl.create(
        :live_content_item,
        content_id: content_id,
        locale: "en",
        base_path: "/content.en",
        format: "topic",
        lock_version: 2,
      )
      @ar_live_content = FactoryGirl.create(
        :live_content_item,
        content_id: content_id,
        locale: "ar",
        base_path: "/content.ar",
        format: "topic",
        lock_version: 2,
      )
    end

    context "without providing a locale parameter" do
      before do
        get :index, document_type: "topic", fields: %w(locale content_id base_path publication_state)
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the english content item as json" do
        parsed_response_body = JSON.parse(response.body)["results"]
        expect(parsed_response_body.length == 2)

        base_paths = parsed_response_body.map { |item| item.fetch("base_path") }
        expect(base_paths). to eq ["/content.en"]

        publication_states = parsed_response_body.map { |item| item.fetch("publication_state") }
        expect(publication_states). to eq ["live"]
      end
    end

    context "providing a specific locale parameter" do
      before do
        get :index, document_type: "topic", fields: %w(locale content_id base_path publication_state), locale: "ar"
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the specific locale content item as json" do
        parsed_response_body = JSON.parse(response.body)["results"]
        expect(parsed_response_body.length == 2)

        base_paths = parsed_response_body.map { |item| item.fetch("base_path") }
        expect(base_paths). to eq ["/content.ar"]

        base_paths = parsed_response_body.map { |item| item.fetch("publication_state") }
        expect(base_paths). to eq ["live"]
      end
    end

    context "providing a locale parameter set to 'all'" do
      before do
        get :index, document_type: "topic", fields: %w(locale content_id base_path publication_state), locale: "all"
      end

      let(:parsed_response_body) { JSON.parse(response.body)["results"] }

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "has the corrent number of items" do
        expect(parsed_response_body.length == 4)
      end

      it "responds with all the localised content items as json" do
        base_paths = parsed_response_body.map { |item| item.fetch("base_path") }
        expect(base_paths.sort). to eq ["/content.en", "/content.ar"].sort
      end

      it "has the correct publication states" do
        publication_states = parsed_response_body.map { |item| item.fetch("publication_state") }
        expect(publication_states). to eq %w(live live)
      end
    end

    context "with pagination params" do
      before do
        get :index, content_format: "topic", fields: ["content_id"], start: "0", page_size: "20"
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end
      it "responds with the content item as json" do
        parsed_response_body = JSON.parse(response.body)["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq("#{content_id}")
      end
    end

    context "without pagination params" do
      before do
        get :index, content_format: 'topic', fields: ['content_id']
      end
      it "is successful" do
        expect(response.status).to eq(200)
      end
      it "responds with the content item as json" do
        parsed_response_body = JSON.parse(response.body)["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq("#{content_id}")
      end
    end

    context "with all_items param" do
      before do
        get :index, content_format: "topic", fields: ["content_id"], all_items: "true"
      end
      it "is successful" do
        expect(response.status).to eq(200)
      end
      it "responds with the content item as json" do
        parsed_response_body = JSON.parse(response.body)["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq("#{content_id}")
      end
    end

    context "with link filtering params" do
      before do
        org_content_id = SecureRandom.uuid
        link_set = FactoryGirl.create(:link_set, content_id: content_id)
        FactoryGirl.create(:link, link_set: link_set, target_content_id: org_content_id)

        get :index, content_format: "topic", fields: ["content_id"], link_organisations: org_content_id.to_s
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content items for the given organistion as json" do
        parsed_response_body = JSON.parse(response.body)["results"]
        expect(parsed_response_body.first.fetch("content_id")).to eq("#{content_id}")
      end
    end
  end

  describe "show" do
    context "for an existing content item" do
      before do
        get :show, content_id: content_id
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content item as json" do
        parsed_response_body = JSON.parse(response.body)
        expect(parsed_response_body.fetch("content_id")).to eq("#{content_id}")
      end
    end

    context "for a non-existent content item" do
      it "responds with 404" do
        get :show, content_id: "missing"

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
        put :put_content, content_id: SecureRandom.uuid
      end

      it "responds with 200" do
        expect(response.status).to eq(200)
      end

      it "responds with the content item" do
        parsed_response_body = JSON.parse(response.body)
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
        put :put_content, content_id: content_id
      end

      it "responds with 200" do
        expect(response.status).to eq(200)
      end

      it "responds with the content item" do
        parsed_response_body = JSON.parse(response.body)
        expect(parsed_response_body["content_id"]).to eq(content_id)
      end
    end

    context "with invalid request body" do
      before do
        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = ""
        put :put_content, content_id: content_id
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
        post :publish, content_id: content_id
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the content_id of the published item" do
        parsed_response_body = JSON.parse(response.body)
        expect(parsed_response_body.keys).to include("content_id")
        expect(parsed_response_body["content_id"]).not_to be_nil
      end
    end

    context "for a non-existent content item" do
      it "responds with 404" do
        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = { update_type: "major" }.to_json
        post :publish, content_id: "missing"

        expect(response.status).to eq(404)
      end
    end
  end

  describe "index" do
    before do
      create(:draft_content_item, publishing_app: 'publisher', base_path: '/content')
      create(:draft_content_item, publishing_app: 'whitehall', base_path: '/item1')
      create(:draft_content_item, publishing_app: 'whitehall', base_path: '/item2')
      create(:draft_content_item, publishing_app: 'specialist_publisher', base_path: '/item3')
    end

    it "displays items filtered by the user's app_name" do
      request.env['warden'].user.app_name = 'whitehall'
      get :index, document_type: 'guide', fields: %w(base_path publishing_app)
      items = JSON.parse(response.body)["results"]
      expect(items.length).to eq(2)
      expect(items.all? { |i| i["publishing_app"] == 'whitehall' }).to be true
    end

    it "displays all items if user has 'view_all' permission" do
      request.env['warden'].user.permissions << 'view_all'
      get :index, document_type: 'guide', fields: %w(base_path publishing_app)
      items = JSON.parse(response.body)["results"]
      expect(items.length).to eq(4)
      expect(items.map { |i| i["publishing_app"] }.uniq).to match_array(%w(whitehall specialist_publisher publisher))
    end
  end
end
