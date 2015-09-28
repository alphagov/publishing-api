module RequestHelpers
  module DownstreamRequests
    def url_registration_happens
      it "registers with the URL with the URL arbiter" do
        expect(PublishingAPI.service(:url_arbiter)).to receive(:reserve_path).with(
          "/vat-rates",
          publishing_app: content_item[:publishing_app]
        )

        put_content_item
      end
    end

    def url_registration_failures_422
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

    def sends_to_draft_content_store
      it "sends to draft content store after registering the URL" do
        expect(PublishingAPI.service(:url_arbiter)).to receive(:reserve_path).ordered
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item,
          )
          .ordered

        put_content_item
      end
    end
  end
end
