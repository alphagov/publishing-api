RSpec.describe "Endpoint behaviour", type: :request do
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
      put "/v2/content/#{content_id}", params: content_item.to_json
      expect(response.status).to eq(200)
    end

    it "responds with the presented edition" do
      put "/v2/content/#{content_id}", params: content_item.to_json

      updated_edition = Edition.with_document.find_by!("documents.content_id": content_id)
      presented_content_item = Presenters::Queries::ContentItemPresenter.present(
        updated_edition,
        include_warnings: true,
      )

      expect(response.body).to eq(presented_content_item.to_json)
    end

    context "with invalid json" do
      it "responds with 400" do
        put "/v2/content/#{content_id}", params: "Not JSON"
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
        put "/v2/content/#{content_id}", params: content_item.to_json

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

        put "/v2/content/#{content_id}", params: content_item.to_json
      end
    end

    context "with the root path as a base_path" do
      let(:base_path) { "/" }

      it "creates the edition" do
        put "/v2/content/#{content_id}", params: content_item.to_json

        expect(response.status).to eq(200)
        expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
      end
    end

    it "validates path ownership" do
      put "/v2/content/#{content_id}", params: content_item.to_json

      expect(PathReservation.count).to eq(1)
      expect(PathReservation.first.base_path).to eq(base_path)
      expect(PathReservation.first.publishing_app).to eq(content_item[:publishing_app])
    end
  end

  context "GET /v2/content/:content_id" do
    let(:content_id) { SecureRandom.uuid }

    context "when the document exists" do
      let(:document) { create(:document, content_id: content_id) }
      let!(:edition) { create(:draft_edition, document: document) }

      it "responds with 200" do
        get "/v2/content/#{content_id}"
        expect(response.status).to eq(200)
      end

      it "responds with the presented edition" do
        get "/v2/content/#{content_id}"

        updated_edition = Edition.with_document.find_by!("documents.content_id": content_id)
        presented_content_item = Presenters::Queries::ContentItemPresenter.present(
          updated_edition,
          include_warnings: true,
        )

        expect(response.body).to eq(presented_content_item.to_json)
      end
    end

    context "when the document does not exist" do
      it "responds with 404" do
        get "/v2/content/#{SecureRandom.uuid}"
        expect(response.status).to eq(404)
      end
    end

    context "when an invalid UUID is used as content_id" do
      it "responds with 404" do
        expect {
          get "/v2/content/INVALID_UUID"
        }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  context "/links" do
    context "PATCH /v2/links/:content_id" do
      context "when creating a link set for a document to be added later" do
        it "responds with 200" do
          patch "/v2/links/#{SecureRandom.uuid}", params: { links: {} }.to_json

          expect(response.status).to eq(200)
        end
      end
    end
  end
end
