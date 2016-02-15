require "rails_helper"

RSpec.describe "PUT endpoint pact with the Content Store", pact: true do
  include Pact::Consumer::RSpec
  include RequestHelpers::Mocks

  let!(:content_item) { FactoryGirl.create(:live_content_item, content_id: content_id) }
  let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_id) }

  let(:client) { ContentStoreWriter.new("http://localhost:3093") }
  let(:body) { Presenters::ContentStorePresenter.present(content_item) }

  context "a content item exists" do
    before do
      content_store
        .given("a content item exists with base_path /vat-rates")
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

    it "accepts the messages to the content store" do
      response = client.put_content_item(base_path: "/vat-rates", content_item: body)
      expect(response.code).to eq(200)
    end
  end
end
