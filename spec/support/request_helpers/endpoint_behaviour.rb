module RequestHelpers
  module EndpointBehaviour
    def returns_200_response
      it "responds with the content item as a 200" do
        do_request

        expect(response.status).to eq(200)
        expect(response.body).to eq(content_item.to_json)
      end
    end

    def returns_400_on_invalid_json
      it "returns a 400 if the JSON is invalid" do
        do_request(body: "not a JSON")

        expect(response.status).to eq(400)
      end
    end

    def suppresses_draft_content_store_502s
      context "when draft content store is not running but draft 502s are suppressed" do
        before do
          @swallow_draft_errors = PublishingAPI.swallow_draft_connection_errors
          PublishingAPI.swallow_draft_connection_errors = true
          stub_request(:put, %r{^http://draft-content-store.*/content/.*})
            .to_return(status: 502)
        end

        it "returns the normal 200 response" do
          begin
            do_request

            expect(response.status).to eq(200)
            expect(response.body).to eq(content_item.to_json)
          ensure
            PublishingAPI.swallow_draft_connection_errors = @swallow_draft_errors
          end
        end
      end
    end

    def forwards_locale_extension
      context "with a translation URL" do
        let(:base_path) { "/vat-rates.pl" }

        it "passes through the locale extension" do
          expect(PublishingAPI.service(:draft_content_store)).to receive(:put_content_item)
            .with(hash_including(base_path: base_path))

          do_request
        end
      end
    end

    def accepts_root_path
      context "with the root path as a base_path" do
        let(:base_path) { "/" }

        it "creates the content item" do
          do_request

          expect(response.status).to eq(200)
          expect(a_request(:put, %r{.*/(content|publish-intent)/$})).to have_been_made.at_least_once
        end
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::EndpointBehaviour, :type => :request
