module RequestHelpers
  module DownstreamRequests
    def url_registration_happens
      it "registers the URL with the URL arbiter" do
        expect(PublishingAPI.service(:url_arbiter)).to receive(:reserve_path).with(
          "/vat-rates",
          publishing_app: content_item_params[:publishing_app]
        )

        do_request
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
          Timecop.freeze # So that timestamps match between expectation and stub.
          url_arbiter_returns_validation_error_for("/vat-rates",
            "path" => ["is not valid"]
          )
        end

        it "returns a 422 with the URL arbiter's response body" do
          do_request

          expect(response.status).to eq(422)
          expect(response.body).to eq(url_arbiter_response_body)
        end
      end

      context "when the path is taken" do
        let(:expected_error_response_body) {
          {
            "error" => {
              "code" => 409,
              "message" => "/vat-rates is reserved",
              "fields" => {
                "base_path" => ["is already reserved by the whitehall application"]
              }
            }
          }.to_json
        }

        before do
          Timecop.freeze # So that timestamps match between expectation and stub.
          url_arbiter_has_registration_for("/vat-rates", "whitehall")
        end

        it "returns a 409 with the URL arbiter's response body" do
          do_request

          expect(response.status).to eq(409)
          expect(response.body).to eq(expected_error_response_body)
        end
      end

      context "when the URL arbiter has an internal error" do
        before do
          stub_request(:put, /url-arbiter/).to_return(status: 506)
        end

        it "returns a 500 with a custom error message" do
          do_request

          expect(response.status).to eq(500)
          expect(response.body).to eq({
            "error" => {
              "code" => 500,
              "message" => "Unexpected error whilst registering with url-arbiter: 506 Variant Also Negotiates"
            }
          }.to_json)
        end
      end
    end

    def sends_to_draft_content_store(with_arbitration: true)
      it "sends to draft content store after registering the URL" do
        expect(PublishingAPI.service(:url_arbiter)).to receive(:reserve_path).ordered if with_arbitration
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_draft_content_store,
          )
          .ordered

        do_request

        expect(response.status).to eq(200), response.body
      end
    end

    def sends_to_live_content_store
      it "sends to live content store after registering the URL" do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: content_item_for_live_content_store,
          )

        do_request

        expect(response.status).to eq(200), response.body
      end
    end

    def does_not_send_to_live_content_store
      it "does not send anything to the live content store" do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /[^-]content-store.*/)

        do_request
      end
    end

    def does_not_send_to_draft_content_store
      it "does not send anything to the draft content store" do
        expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item).never
        expect(WebMock).not_to have_requested(:any, /draft-content-store.*/)

        do_request
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::DownstreamRequests, :type => :request
