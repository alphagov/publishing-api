module RequestHelpers
  def base_path
    "/vat-rates"
  end

  def content_item_without_access_limiting
    {
      content_id: "582e1d3f-690e-4115-a948-e05b3c6b3d88",
      title: "VAT rates",
      description: "VAT rates for goods and services",
      format: "guide",
      need_ids: ["100123", "100124"],
      public_updated_at: "2014-05-14T13:00:06Z",
      publishing_app: "mainstream_publisher",
      rendering_app: "mainstream_frontend",
      locale: "en",
      phase: "beta",
      details: {
        body: "<p>Something about VAT</p>\n",
      },
      routes: [
        {
          path: "/vat-rates",
          type: "exact",
        }
      ],
      update_type: "major",
    }
  end

  def content_item_with_access_limiting
    content_item_without_access_limiting.merge(
      access_limited: {
        users: [
          "f17250b0-7540-0131-f036-005056030202",
          "74c7d700-5b4a-0131-7a8e-005056030037",
        ],
      },
    )
  end

  def put_content_item(body: content_item.to_json)
    put request_path, body
  end

  def check_url_registration_happens
    it "registers with the URL with the URL arbiter" do
      expect(PublishingAPI.service(:url_arbiter)).to receive(:reserve_path).with(
        "/vat-rates",
        publishing_app: content_item[:publishing_app]
      )

      put_content_item
    end
  end

  def check_url_registration_failures
    context "when the path is invalid" do
      let(:url_arbiter_response_body) {
        url_arbiter_data_for("/vat-rates",
          "errors" => {
            "path" => ["is not valid"]
          }
        ).to_json
      }

      before do
        url_arbiter_returns_validation_error_for("/vat-rates",
          "path" => ["is not valid"]
        )
      end

      it "returns a 422 with the URL arbiter's response body" do
        put_content_item

        expect(response.status).to eq(422)
        expect(response.body).to eq(url_arbiter_response_body)
      end
    end

    context "when the path is taken" do
      let(:url_arbiter_response_body) {
        url_arbiter_data_for("/vat-rates",
          "publishing_app" => "whitehall",
          "errors" => {
            "path" => ["is already reserved by the whitehall application"]
          }
        ).to_json
      }

      before do
        url_arbiter_has_registration_for("/vat-rates", "whitehall")
      end

      it "returns a 409 with the URL arbiter's response body" do
        put_content_item

        expect(response.status).to eq(409)
        expect(response.body).to eq(url_arbiter_response_body)
      end
    end

    context "when the URL arbiter has an internal error" do
      before do
        stub_request(:put, /url-arbiter/).to_return(status: 506)
      end

      it "returns a 500 with a custom error message" do
        put_content_item

        expect(response.status).to eq(500)
        expect(response.body).to eq({
          message: "Unexpected error whilst registering with url-arbiter: 506 Variant Also Negotiates"
        }.to_json)
      end
    end
  end

  def check_200_response
    it "responds with the content item as a 200" do
      put_content_item

      expect(response.status).to eq(200)
      expect(response.body).to eq(content_item.to_json)
    end
  end

  def check_400_on_invalid_json
    it "returns a 400 if the JSON is invalid" do
      put_content_item(body: "not a JSON")

      expect(response.status).to eq(400)
    end
  end

  def check_draft_content_store_502_suppression
    context "when draft content store is not running but draft 502s are suppressed" do
      before do
        @swallow_draft_errors = PublishingAPI.swallow_draft_connection_errors
        PublishingAPI.swallow_draft_connection_errors = true
        stub_request(:put, %r{^http://draft-content-store.*/content/.*})
          .to_return(status: 502)
      end

      it "returns the normal 200 response" do
        begin
          put_content_item

          expect(response.status).to eq(200)
          expect(response.body).to eq(content_item.to_json)
        ensure
          PublishingAPI.swallow_draft_connection_errors = @swallow_draft_errors
        end
      end
    end
  end

  def check_forwards_locale_extension
    context "with a translation URL" do
      let(:base_path) { "/vat-rates.pl" }

      it "passes through the locale extension" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(hash_including(base_path: base_path))

        put_content_item
      end
    end
  end

  def check_accepts_root_path
    context "with the root path as a base_path" do
      let(:base_path) { "/" }

      it "creates the content item" do
        put_content_item

        expect(response.status).to eq(200)
        expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
      end
    end
  end
end
