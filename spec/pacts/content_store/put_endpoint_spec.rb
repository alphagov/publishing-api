require "rails_helper"

RSpec.describe "PUT endpoint pact with the Content Store", pact: true do
  include Pact::Consumer::RSpec
  include RequestHelpers::Mocks

  let!(:content_item) do
    FactoryGirl.create(
      :live_content_item,
      content_id: content_id
    )
  end

  let!(:content_store_payload_version) do
    create(:content_store_payload_version, content_item_id: content_item.id)
  end

  let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_id) }

  let(:client) { ContentStoreWriter.new("http://localhost:3093") }
  let(:body) { Presenters::ContentStorePresenter.present(content_item) }

  context "when a content item exists that has an older payload_version than the request" do
    before do
      content_store
        .given("a content item exists with base_path /vat-rates and version 0")
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
          status: 200,
          body: {},
          headers: {
            "Content-Type" => "application/json; charset=utf-8"
          },
        )
    end
  end

  describe "V1" do
    let(:attributes) { content_item_params }
    let(:body) do
      Presenters::DownstreamPresenter::V1.present(
        attributes, update_type: false
      )
    end
    let!(:content_store_payload_version) do
      create(:v1_content_store_payload_version)
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
        response = client.put_content_item(base_path: "/vat-rates", content_item: body)
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
            status: 200,
            body: {},
            headers: {
              "Content-Type" => "application/json; charset=utf-8"
            },
          )
      end
    end
  end
end
