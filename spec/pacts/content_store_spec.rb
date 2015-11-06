require "rails_helper"

RSpec.describe "Pact with the Content Store", pact: true do
  include Pact::Consumer::RSpec

  let(:client) { ContentStoreWriter.new("http://localhost:3093") }
  let(:body) do
    {
      content_id: "7271a331-bbdd-411e-abb9-00127b1fae86",
      base_path: "/vat-rates",
      transmitted_at: 1000000000.0000001,
      analytics_identifier: "GDS01",
      description: "VAT rates for goods and services",
      details: {:body=>"<p>Something about VAT</p>\n"},
      format: "guide",
      links: { organisations: ["46dbf5f6-9c67-4fd2-94fb-4928f9d21857"] },
      locale: "en",
      need_ids: ["100123", "100124"],
      phase: "beta",
      public_updated_at: "2014-05-14T13:00:06Z",
      publishing_app: "mainstream_publisher",
      redirects: [],
      rendering_app: "mainstream_frontend",
      routes: [{:path=>"/vat-rates", :type=>"exact"}],
      title: "VAT rates",
    }
  end

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
