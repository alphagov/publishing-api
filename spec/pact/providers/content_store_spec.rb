# frozen_string_literal: true

RSpec.describe "Verify the pact with Content Store", :pact do
  include RequestHelpers::Mocks

  has_http_pact_between "Publishing API", "Content Store", opts: {
    pact_dir: ENV.fetch("PACT_PACT_DIR", Rails.root.join("spec/pacts").to_s),
    pact_specification: ENV.fetch("PACT_SPEC_VERSION", "V3"),
  }

  describe "PUT endpoint" do
    let(:base_path) { "/vat-rates" }
    let!(:event) { double(:event, id: 5) }
    let!(:link_set) { create(:link_set, content_id:) }

    let!(:edition) do
      create(
        :live_edition,
        document: create(:document, content_id:),
        base_path:,
      )
    end

    let(:body) do
      Presenters::EditionPresenter.new(
        edition, draft: false
      ).for_content_store(event.id)
    end

    def exercise_put_content_item(mock_server)
      client = ContentStoreWriter.new(mock_server.url)
      client.put_content_item(base_path:, content_item: body)
    end

    context "when a content item exists that has an older payload_version than the request" do
      it "accepts in-order messages to the content store" do
        new_interaction("a request to create a content item")
          .given("a content item exists with base_path /vat-rates and payload_version 0")
          .with_request(
            method: :put,
            path: "/content/vat-rates",
            body:,
            headers: { "Content-Type" => "application/json" },
          )
          .will_respond_with(
            status: 200,
            body: {},
            headers: { "Content-Type" => "application/json; charset=utf-8" },
          )

        execute_http_pact do |mock_server|
          response = exercise_put_content_item(mock_server)
          expect(response.code).to eq(200)
        end
      end
    end

    context "when a content item exists that has a higher payload_version than the request" do
      it "rejects out-of-order messages to the content store" do
        new_interaction("a request to create a content item")
          .given("a content item exists with base_path /vat-rates and payload_version 10")
          .with_request(
            method: :put,
            path: "/content/vat-rates",
            body:,
            headers: {
              "Content-Type" => "application/json",
            },
          )
          .will_respond_with(
            status: 409,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8",
            },
          )

        execute_http_pact do |mock_server|
          expect {
            exercise_put_content_item(mock_server)
          }.to raise_error(GdsApi::HTTPConflict)
        end
      end
    end

    describe "V1" do
      let(:attributes) { content_item_params }

      # The FFI mock server serialises Ruby objects differently to the v1 mock
      # service (e.g. Time#to_s rather than ActiveSupport's ISO8601 to_json),
      # so normalise the expected body the same way ContentStoreWriter will
      # serialise it when it makes the request.
      let(:body) do
        JSON.parse(attributes.except(:update_type).merge(payload_version: event.id).to_json)
      end

      context "when a content item exists that has an lower payload_version than the request" do
        it "accepts in-order messages to the content store" do
          new_interaction("a request to create a content item originating from v1 endpoint")
            .given("a content item exists with base_path /vat-rates and payload_version 0")
            .with_request(
              method: :put,
              path: "/content/vat-rates",
              body:,
              headers: {
                "Content-Type" => "application/json",
              },
            )
            .will_respond_with(
              status: 200,
              body: {},
              headers: {
                "Content-Type" => "application/json; charset=utf-8",
              },
            )

          execute_http_pact do |mock_server|
            response = exercise_put_content_item(mock_server)
            expect(response.code).to eq(200)
          end
        end
      end

      context "when a content item exists that has a higher payload_version than the request" do
        it "rejects out-of-order messages to the content store" do
          new_interaction("a request to create a content item originating from v1 endpoint")
            .given("a content item exists with base_path /vat-rates and payload_version 10")
            .with_request(
              method: :put,
              path: "/content/vat-rates",
              body:,
              headers: {
                "Content-Type" => "application/json",
              },
            )
            .will_respond_with(
              status: 409,
              body: {},
              headers: {
                "Content-Type" => "application/json; charset=utf-8",
              },
            )

          execute_http_pact do |mock_server|
            expect {
              exercise_put_content_item(mock_server)
            }.to raise_error(GdsApi::HTTPConflict)
          end
        end
      end
    end
  end

  describe "DELETE endpoint" do
    context "when the content item exists in the content store" do
      it "responds with a 200 status code" do
        new_interaction("a request to delete the content item")
          .given("a content item exists with base_path /vat-rates")
          .with_request(
            method: :delete,
            path: "/content/vat-rates",
          )
          .will_respond_with(
            status: 200,
          )

        execute_http_pact do |mock_server|
          client = ContentStoreWriter.new(mock_server.url)
          response = client.delete_content_item("/vat-rates")
          expect(response.code).to eq(200)
        end
      end
    end

    context "when the content item does not exist in the content store" do
      it "responds with a 404 status code" do
        new_interaction("a request to delete the content item")
          .given("no content item exists with base_path /vat-rates")
          .with_request(
            method: :delete,
            path: "/content/vat-rates",
          )
          .will_respond_with(
            status: 404,
          )

        execute_http_pact do |mock_server|
          client = ContentStoreWriter.new(mock_server.url)
          expect {
            client.delete_content_item("/vat-rates")
          }.to raise_error(GdsApi::HTTPNotFound)
        end
      end
    end
  end
end
