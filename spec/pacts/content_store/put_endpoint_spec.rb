require "rails_helper"

RSpec.describe "PUT endpoint pact with the Content Store", pact: true do
  include Pact::Consumer::RSpec
  include RequestHelpers::Mocks

  let!(:content_item) { FactoryGirl.create(:live_content_item, content_id: content_id) }
  let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_id) }

  let(:client) { ContentStoreWriter.new("http://localhost:3093") }
  let(:body) { Presenters::ContentStorePresenter.present(content_item) }
  let(:request_time) { Time.at(2000000000) }

  around do |example|
    Timecop.freeze(request_time) { example.run }
  end

  context "when a content item exists that has an older transmitted_at than the request" do
    before do
      content_store
        .given("a content item exists with base_path /vat-rates and transmitted_at 1000000000000000000")
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
      response = client.put_content_item(base_path: "/vat-rates", content_item: body)
      expect(response.code).to eq(200)
    end
  end

  context "when a content item exists that has a newer transmitted_at than the request" do
    before do
      content_store
        .given("a content item exists with base_path /vat-rates and transmitted_at 3000000000000000000")
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
        client.put_content_item(base_path: "/vat-rates", content_item: body)
      }.to raise_error(GdsApi::HTTPConflict)
    end
  end

  describe "V1" do
    let(:attributes) { content_item_params }
    let(:body) do
      Presenters::DownstreamPresenter::V1.present(
        attributes, access_limited: false, update_type: false
      )
    end

    context "when a content item exists that has an older transmitted_at than the request" do
      before do
        content_store
          .given("a content item exists with base_path /vat-rates and transmitted_at 1000000000000000000")
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
        response = client.put_content_item(base_path: "/vat-rates", content_item: body)
        expect(response.code).to eq(200)
      end
    end

    context "when a content item exists that has a newer transmitted_at than the request" do
      before do
        content_store
          .given("a content item exists with base_path /vat-rates and transmitted_at 3000000000000000000")
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
          client.put_content_item(base_path: "/vat-rates", content_item: body)
        }.to raise_error(GdsApi::HTTPConflict)
      end
    end
  end
end
