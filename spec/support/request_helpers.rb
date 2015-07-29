module RequestHelpers
  def check_url_registration_happens
    it "registers with the URL with the URL arbiter" do
      expect(PublishingAPI.services(:url_arbiter)).to receive(:reserve_path).with(
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

  def check_content_type_header
    it "passes through the Content-Type header from the live content store" do
      stub_request(:put, %r{.*content-store.*/content/.*}).to_return(headers: {
        "Content-Type" => "application/vnd.ms-powerpoint"
      })

      put_content_item

      expect(response["Content-Type"]).to include("application/vnd.ms-powerpoint")
    end
  end

  def check_draft_content_store_502_suppression
    context "when draft content store is not running but draft 502s are suppressed" do
      before do
        @draft_store_502_setting = ENV["SUPPRESS_DRAFT_STORE_502_ERROR"]
        ENV["SUPPRESS_DRAFT_STORE_502_ERROR"] = "1"
        stub_request(:put, %r{^http://draft-content-store.*/content/.*})
          .to_return(status: 502)
      end

      it "returns the normal 200 response" do
        begin
          put_content_item

          expect(response.status).to eq(200)
          expect(response.body).to eq(content_item.to_json)
        ensure
          ENV["SUPPRESS_DRAFT_STORE_502_ERROR"] = @draft_store_502_setting
        end
      end
    end
  end
end
