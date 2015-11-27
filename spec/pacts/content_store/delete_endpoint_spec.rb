require "rails_helper"

RSpec.describe "DELETE endpoint pact with the Content Store", pact: true do
  include Pact::Consumer::RSpec

  let(:client) { ContentStoreWriter.new("http://localhost:3093") }

  context "when the content item exists in the content store" do
    before do
      content_store
        .given("a content item exists with base path /vat-rates")
        .upon_receiving("a request to delete the content item")
        .with(
          method: :delete,
          path: "/content/vat-rates",
        )
        .will_respond_with(
          status: 200,
        )
    end

    it "responds with a 200 status code" do
      response = client.delete_content_item("/vat-rates")
      expect(response.code).to eq(200)
    end
  end

  context "when the content item does not exist in the content store" do
    before do
      content_store
        .given("no content item exists with base path /vat-rates")
        .upon_receiving("a request to delete the content item")
        .with(
          method: :delete,
          path: "/content/vat-rates",
        )
        .will_respond_with(
          status: 404,
        )
    end

    it "responds with a 404 status code" do
      expect {
        client.delete_content_item("/vat-rates")
      }.to raise_error(GdsApi::HTTPNotFound)
    end
  end
end
