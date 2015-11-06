require "rails_helper"

RSpec.describe "Pact with the Content Store", pact: true do
  include Pact::Consumer::RSpec
  let!(:content_item) { FactoryGirl.create(:live_content_item) }
  let!(:link_set) { FactoryGirl.create(:link_set, content_id: content_item.content_id) }

  let(:client) { ContentStoreWriter.new("http://localhost:3093") }
  let(:body) { Presenters::ContentStorePresenter.present(content_item) }

  it "accepts in-order messages to the content store" do
    content_store
    .given("an in-order request was sent to the content store")
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

    response = client.put_content_item(base_path: "/vat-rates", content_item: body)
    expect(response.code).to eq(200)
  end

  it "rejects out-of-order messages to the content store" do
    content_store
    .given("an out-of-order request was sent to the content store")
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

    expect {
      client.put_content_item(base_path: "/vat-rates", content_item: body)
    }.to raise_error(GdsApi::HTTPConflict)
  end
end
