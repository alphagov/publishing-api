require "rails_helper"

RSpec.describe V2::ContentItemsController do
  let(:content_id) { SecureRandom.uuid }

  before do
    stub_request(:any, /content-store/)
    @draft = FactoryGirl.create(:draft_content_item, content_id: content_id)
    FactoryGirl.create(:version, target: @draft, number: 2)
  end

  describe "index" do
    let(:en_draft_content_id) { SecureRandom.uuid }
    let(:ar_draft_content_id) { SecureRandom.uuid }
    let(:en_live_content_id) { SecureRandom.uuid }
    let(:ar_live_content_id) { SecureRandom.uuid }

    before do
      @en_draft_content = FactoryGirl.create(:draft_content_item,
        content_id: en_draft_content_id,
        locale: "en",
        base_path: "/content.en",
        format: "topic")
      @ar_draft_content = FactoryGirl.create(:draft_content_item,
        content_id: ar_draft_content_id,
        locale: "ar",
        base_path: "/content.ar",
        format: "topic")
      @en_live_content = FactoryGirl.create(:live_content_item,
        content_id: en_live_content_id,
        locale: "en",
        base_path: "/content.en",
        format: "topic")
      @ar_live_content = FactoryGirl.create(:live_content_item,
        content_id: ar_live_content_id,
        locale: "ar",
        base_path: "/content.ar",
        format: "topic")
      FactoryGirl.create(:version, target: @en_draft_content, number: 2)
      FactoryGirl.create(:version, target: @ar_draft_content, number: 2)
      FactoryGirl.create(:version, target: @en_live_content, number: 2)
      FactoryGirl.create(:version, target: @ar_live_content, number: 2)
    end

    context "without providing a locale parameter" do
      before do
        get :index, content_format: "topic", fields: ["locale","content_id","base_path"]
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the english content item as json" do
        parsed_response_body = JSON.parse(response.body)
        expect(parsed_response_body.length == 2)
        expect(parsed_response_body.first.fetch("content_id")).to eq("#{en_draft_content_id}")
        expect(parsed_response_body.second.fetch("content_id")).to eq("#{en_live_content_id}")
      end
    end

    context "providing a specific locale parameter" do
      before do
        get :index, content_format: "topic", fields: ["locale","content_id","base_path"], locale: "ar"
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with the specific locale content item as json" do
        parsed_response_body = JSON.parse(response.body)
        expect(parsed_response_body.length == 2)
        expect(parsed_response_body.first.fetch("content_id")).to eq("#{ar_draft_content_id}")
        expect(parsed_response_body.second.fetch("content_id")).to eq("#{ar_live_content_id}")
      end
    end

    context "providing a locale parameter set to 'all'" do
      before do
        get :index, content_format: "topic", fields: ["locale","content_id","base_path"], locale: "all"
      end

      it "is successful" do
        expect(response.status).to eq(200)
      end

      it "responds with all the localised content items as json" do
        parsed_response_body = JSON.parse(response.body)
        expect(parsed_response_body.length == 4)
        expect(parsed_response_body[0].fetch("content_id")).to eq("#{en_draft_content_id}")
        expect(parsed_response_body[1].fetch("content_id")).to eq("#{ar_draft_content_id}")
        expect(parsed_response_body[2].fetch("content_id")).to eq("#{ar_live_content_id}")
        expect(parsed_response_body[3].fetch("content_id")).to eq("#{en_live_content_id}")
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
          .merge("routes" => [{"path" => "/that-rates", "type" => "exact"}])
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
        request.env["CONTENT_TYPE"] = "application/json"
        request.env["RAW_POST_DATA"] = @draft.to_json
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
end
