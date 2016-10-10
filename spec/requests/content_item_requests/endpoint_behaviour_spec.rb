require "rails_helper"

RSpec.describe "Endpoint behaviour", type: :request do
  context "/content" do
    let(:content_item) { content_item_params }

    it "responds with 200" do
      put "/content#{base_path}", content_item_params.to_json
      expect(response.status).to eq(200)
    end

    it "responds with the request body" do
      put "/content#{base_path}", content_item_params.to_json
      expect(response.body).to eq(content_item_params.to_json)
    end

    context "with invalid json" do
      it "responds with 400" do
        put "/content#{base_path}", "Not JSON"
        expect(response.status).to eq(400)
      end
    end

    context "when draft content store is not running but draft 502s are suppressed" do
      before do
        @swallow_connection_errors = PublishingAPI.swallow_connection_errors
        PublishingAPI.swallow_connection_errors = true
        stub_request(:put, %r{^http://draft-content-store.*/content/.*})
          .to_return(status: 502)
      end

      after do
        PublishingAPI.swallow_connection_errors = @swallow_connection_errors
      end

      it "returns the normal 200 response" do
        put "/content#{base_path}", content_item_params.to_json

        parsed_response_body = parsed_response
        expect(response.status).to eq(200)
        expect(parsed_response_body["content_id"]).to eq(content_item[:content_id])
        expect(parsed_response_body["title"]).to eq(content_item[:title])
      end
    end

    context "with a translation URL" do
      let(:base_path) { "/vat-rates.pl" }

      it "passes through the locale extension" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(hash_including(base_path: base_path))
          .at_least(:once)

        put "/content#{base_path}", content_item_params.to_json
      end
    end

    context "with the root path as a base_path" do
      let(:base_path) { "/" }

      it "creates the content item" do
        put "/content#{base_path}", content_item_params.to_json

        expect(response.status).to eq(200)
        expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
      end
    end

    it "validates path ownership" do
      put "/content#{base_path}", content_item_params.to_json

      expect(PathReservation.count).to eq(1)
      expect(PathReservation.first.base_path).to eq(base_path)
      expect(PathReservation.first.publishing_app).to eq(content_item[:publishing_app])
    end

    context "without a content id" do
      let(:request_body) {
        content_item.except(:content_id).to_json
      }

      it "responds with 200" do
        put "/content#{base_path}", content_item.except(:content_id).to_json
        expect(response.status).to eq(200)
      end

      it "responds with the request body" do
        body = content_item.except(:content_id).to_json
        put "/content#{base_path}", body
        expect(response.body).to eq(body)
      end

      context "with a translation URL" do
        let(:base_path) { "/vat-rates.pl" }

        it "passes through the locale extension" do
          expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
            .with(hash_including(base_path: base_path))
            .at_least(:once)

          put "/content#{base_path}", content_item.except(:content_id).to_json
        end
      end

      context "with the root path as a base_path" do
        let(:base_path) { "/" }

        it "creates the content item" do
          put "/content#{base_path}", content_item.except(:content_id).to_json

          expect(response.status).to eq(200)
          expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
        end
      end

      it "validates path ownership" do
        put "/content#{base_path}", content_item.except(:content_id).to_json

        expect(PathReservation.count).to eq(1)
        expect(PathReservation.first.base_path).to eq(base_path)
        expect(PathReservation.first.publishing_app).to eq(content_item[:publishing_app])
      end
    end
  end

  context "/draft-content" do
    let(:content_item) { content_item_params }

    it "responds with 200" do
      put "/draft-content#{base_path}", content_item_params.to_json
      expect(response.status).to eq(200)
    end

    it "responds with the request body" do
      put "/draft-content#{base_path}", content_item_params.to_json
      expect(response.body).to eq(content_item_params.to_json)
    end

    context "with invalid json" do
      it "responds with 400" do
        put "/draft-content#{base_path}", "Not JSON"
        expect(response.status).to eq(400)
      end
    end

    context "when draft content store is not running but draft 502s are suppressed" do
      before do
        @swallow_connection_errors = PublishingAPI.swallow_connection_errors
        PublishingAPI.swallow_connection_errors = true
        stub_request(:put, %r{^http://draft-content-store.*/content/.*})
          .to_return(status: 502)
      end

      after do
        PublishingAPI.swallow_connection_errors = @swallow_connection_errors
      end

      it "returns the normal 200 response" do
        put "/draft-content#{base_path}", content_item_params.to_json

        parsed_response_body = parsed_response
        expect(response.status).to eq(200)
        expect(parsed_response_body["content_id"]).to eq(content_item[:content_id])
        expect(parsed_response_body["title"]).to eq(content_item[:title])
      end
    end

    context "with a translation URL" do
      let(:base_path) { "/vat-rates.pl" }

      it "passes through the locale extension" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(hash_including(base_path: base_path))
          .at_least(:once)

        put "/draft-content#{base_path}", content_item_params.to_json
      end
    end

    context "with the root path as a base_path" do
      let(:base_path) { "/" }

      it "creates the content item" do
        put "/draft-content#{base_path}", content_item_params.to_json

        expect(response.status).to eq(200)
        expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
      end
    end

    it "validates path ownership" do
      put "/draft-content#{base_path}", content_item_params.to_json

      expect(PathReservation.count).to eq(1)
      expect(PathReservation.first.base_path).to eq(base_path)
      expect(PathReservation.first.publishing_app).to eq(content_item[:publishing_app])
    end
  end

  context "GET /v2/content" do
    let(:request_path) { "/v2/content?document_type=topic&fields[]=title&fields[]=description" }
    let(:request_body) { "" }
    let(:request_method) { :get }

    it "responds with 200" do
      get "/v2/content?document_type=topic&fields[]=title&fields[]=description"
      expect(response.status).to eq(200)
    end
  end

  context "PUT /v2/content/:content_id" do
    let(:content_item) { v2_content_item }

    it "responds with 200" do
      put "/v2/content/#{content_id}", content_item.to_json
      expect(response.status).to eq(200)
    end

    it "responds with the presented content item" do
      put "/v2/content/#{content_id}", content_item.to_json

      updated_content_item = ContentItem.find_by!(content_id: content_id)
      presented_content_item = Presenters::Queries::ContentItemPresenter.present(
        updated_content_item,
        include_warnings: true,
      )

      expect(response.body).to eq(presented_content_item.to_json)
    end

    context "with invalid json" do
      it "responds with 400" do
        put "/v2/content/#{content_id}", "Not JSON"
        expect(response.status).to eq(400)
      end
    end

    context "when draft content store is not running but draft 502s are suppressed" do
      before do
        @swallow_connection_errors = PublishingAPI.swallow_connection_errors
        PublishingAPI.swallow_connection_errors = true
        stub_request(:put, %r{^http://draft-content-store.*/content/.*})
          .to_return(status: 502)
      end

      after do
        PublishingAPI.swallow_connection_errors = @swallow_connection_errors
      end

      it "returns the normal 200 response" do
        put "/v2/content/#{content_id}", content_item.to_json

        parsed_response_body = parsed_response
        expect(response.status).to eq(200)
        expect(parsed_response_body["content_id"]).to eq(content_item[:content_id])
        expect(parsed_response_body["title"]).to eq(content_item[:title])
      end
    end

    context "with a translation URL" do
      let(:base_path) { "/vat-rates.pl" }

      it "passes through the locale extension" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(hash_including(base_path: base_path))
          .at_least(:once)

        put "/v2/content/#{content_id}", content_item.to_json
      end
    end

    context "with the root path as a base_path" do
      let(:base_path) { "/" }

      it "creates the content item" do
        put "/v2/content/#{content_id}", content_item.to_json

        expect(response.status).to eq(200)
        expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
      end
    end

    it "validates path ownership" do
      put "/v2/content/#{content_id}", content_item.to_json

      expect(PathReservation.count).to eq(1)
      expect(PathReservation.first.base_path).to eq(base_path)
      expect(PathReservation.first.publishing_app).to eq(content_item[:publishing_app])
    end
  end

  context "GET /v2/content/:content_id" do
    let(:content_id) { SecureRandom.uuid }

    context "when the content item exists" do
      let!(:content_item) {
        FactoryGirl.create(
          :draft_content_item,
          content_id: content_id,
        )
      }

      it "responds with 200" do
        get "/v2/content/#{content_id}"
        expect(response.status).to eq(200)
      end

      it "responds with the presented content item" do
        get "/v2/content/#{content_id}"

        updated_content_item = ContentItem.find_by!(content_id: content_id)
        presented_content_item = Presenters::Queries::ContentItemPresenter.present(
          updated_content_item,
          include_warnings: true,
        )

        expect(response.body).to eq(presented_content_item.to_json)
      end

      it "responds with the presented content item for the correct locale" do
        FactoryGirl.create(:draft_content_item, content_id: content_id, locale: "ar")
        presented_content_item = Presenters::Queries::ContentItemPresenter.present(
          content_item,
          include_warnings: true,
        )

        get "/v2/content/#{content_id}"

        expect(response.body).to eq(presented_content_item.to_json)
      end
    end

    context "when the content item does not exist" do
      it "responds with 404" do
        get "/v2/content/#{SecureRandom.uuid}"
        expect(response.status).to eq(404)
      end
    end
  end

  context "/links" do
    context "PATCH /v2/links/:content_id" do
      context "when creating a link set for a content item to be added later" do
        it "responds with 200" do
          patch "/v2/links/#{SecureRandom.uuid}", { links: {} }.to_json

          expect(response.status).to eq(200)
        end
      end
    end
  end
end
