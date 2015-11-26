module RequestHelpers
  module EndpointBehaviour
    def returns_200_response
      it "responds with the content item as a 200" do
        do_request

        expect(response.status).to eq(200)
      end
    end

    def returns_404_response
      it "responds with the content item as a 404" do
        do_request

        expect(response.status).to eq(404)
      end
    end

    def responds_with_request_body
      it "responds with a body that matches the request body" do
        do_request

        expect(response.body).to eq(request_body)
      end
    end

    def responds_with_content_item_body
      it "responds with a body of the content_item" do
        do_request

        expect(response.body).to eq(content_item.to_json)
      end
    end

    def responds_with_presented_content_item
      it "responds with the presentation of the content item and version" do
        do_request

        updated_content_item = DraftContentItem.find_by!(content_id: content_id)
        presented_content_item = Presenters::Queries::ContentItemPresenter.present(updated_content_item)

        expect(response.body).to eq(presented_content_item.to_json)
      end
    end

    def returns_400_on_invalid_json
      it "returns a 400 if the JSON is invalid" do
        do_request(body: "not a JSON")

        expect(response.status).to eq(400)
      end
    end

    def responds_with_presented_correct_locale_content_item
      it "responds with the presentation of content item and version in the correct locale" do
        FactoryGirl.create(:draft_content_item, content_id: content_id, locale: "ar")

        presented_content_item = Presenters::Queries::ContentItemPresenter.present(content_item)

        do_request

        expect(response.body).to eq(presented_content_item.to_json)
      end
    end

    def suppresses_draft_content_store_502s
      context "when draft content store is not running but draft 502s are suppressed" do
        before do
          @swallow_connection_errors = PublishingAPI.swallow_connection_errors
          PublishingAPI.swallow_connection_errors = true
          stub_request(:put, %r{^http://draft-content-store.*/content/.*})
            .to_return(status: 502)
        end

        it "returns the normal 200 response" do
          begin
            do_request

            parsed_response_body = JSON.parse(response.body)
            expect(response.status).to eq(200)
            expect(parsed_response_body["content_id"]).to eq(content_item[:content_id])
            expect(parsed_response_body["title"]).to eq(content_item[:title])
          ensure
            PublishingAPI.swallow_connection_errors = @swallow_connection_errors
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

    def validates_path_ownership
      context "base_path has not already been registered" do
        it "reserves the path for this publishing app" do
          do_request

          expect(PathReservation.count).to eq(1)
          expect(PathReservation.first.base_path).to eq(base_path)
          expect(PathReservation.first.publishing_app).to eq(content_item[:publishing_app])
        end
      end

      context "base_path has already been registered" do
        before do
          create(:path_reservation, base_path: base_path, publishing_app: content_item[:publishing_app])
        end

        it "should be successful if the publishing app matches" do
          expect{ do_request }.not_to change(PathReservation, :count)
          expect(response.status).to eq(200)
        end
      end

      context "base_path has been registered with a different publishing app" do
        before do
          create(:path_reservation, base_path: base_path, publishing_app: "something else")
        end

        it "should be unsuccessful if the publishing app does not match" do
          expect{ do_request }.not_to change(PathReservation, :count)
          expect(response.status).to eq(422)
          expect(PathReservation.last.publishing_app).to eq("something else")
        end
      end
    end
  end
end

RSpec.configuration.extend RequestHelpers::EndpointBehaviour, :type => :request
