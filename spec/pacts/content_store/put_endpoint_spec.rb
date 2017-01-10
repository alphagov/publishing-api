require "rails_helper"

RSpec.describe "PUT endpoint pact with the Content Store", pact: true do
  include Pact::Consumer::RSpec
  include RequestHelpers::Mocks

  let!(:edition) do
    FactoryGirl.create(
      :live_edition,
      content_id: content_id,
      base_path: "/vat-rates"
    )
  end

  let!(:event) { double(:event, id: 5) }
  let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_id) }

  let(:client) { ContentStoreWriter.new("http://localhost:3093") }
  let(:body) {
    Presenters::ContentStorePresenter.present(
      Presenters::DownstreamPresenter.new(
        Queries::GetWebEditions.find(edition.id),
        state_fallback_order: [:published]
      ),
      event.id
    )
  }

  context "when a content item exists that has an older payload_version than the request" do
    before do
      content_store
        .given("a content item exists with base_path /vat-rates and payload_version 0")
        .upon_receiving("a request to create a content item")
        .with(
          method: :put,
          path: "/content/vat-rates",
          body: body,
          headers: {
            "Content-Type" => "application/json"
          },
        )
        .will_respond_with(
          status: 200,
          body: {},
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          },
        )
    end

    it "accepts in-order messages to the content store" do
      response = client.put_edition(base_path: "/vat-rates", edition: body)
      expect(response.code).to eq(200)
    end
  end

  context "when a content item exists that has a higher payload_version than the request" do
    before do
      content_store
        .given("a content item exists with base_path /vat-rates and payload_version 10")
        .upon_receiving("a request to create a content item")
        .with(
          method: :put,
          path: "/content/vat-rates",
          body: body,
          headers: {
            "Content-Type" => "application/json"
          },
        )
        .will_respond_with(
          status: 409,
          body: {},
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          },
        )
    end

    it "rejects out-of-order messages to the content store" do
      expect {
        client.put_edition(base_path: "/vat-rates", edition: body)
      }.to raise_error(GdsApi::HTTPConflict)
    end
  end

  describe "V1" do
    let(:attributes) { edition_params }
    let(:body) do
      attributes.except(:update_type).merge(payload_version: event.id)
    end

    context "when a content item exists that has an lower payload_version than the request" do
      before do
        content_store
          .given("a content item exists with base_path /vat-rates and payload_version 0")
          .upon_receiving("a request to create a content item originating from v1 endpoint")
          .with(
            method: :put,
            path: "/content/vat-rates",
            body: body,
            headers: {
              "Content-Type" => "application/json"
            },
          )
          .will_respond_with(
            status: 200,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8"
            },
          )
      end

      it "accepts in-order messages to the content store" do
        response = client.put_edition(base_path: "/vat-rates", edition: body)
        expect(response.code).to eq(200)
      end
    end

    context "when a content item exists that has a higher payload_version than the request" do
      before do
        content_store
          .given("a content item exists with base_path /vat-rates and payload_version 10")
          .upon_receiving("a request to create a content item originating from v1 endpoint")
          .with(
            method: :put,
            path: "/content/vat-rates",
            body: body,
            headers: {
              "Content-Type" => "application/json"
            },
          )
          .will_respond_with(
            status: 409,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8"
            },
          )
      end

      it "rejects out-of-order messages to the content store" do
        expect {
          client.put_edition(base_path: "/vat-rates", edition: body)
        }.to raise_error(GdsApi::HTTPConflict)
      end
    end
  end
end
