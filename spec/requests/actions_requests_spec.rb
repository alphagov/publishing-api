require "rails_helper"

RSpec.describe "Actions", type: :request do
  include RandomContentHelpers

  it "returns the actions" do
    base_path = "/#{SecureRandom.hex}"
    stub_content_store_calls(base_path)
    edition = generate_random_edition(base_path)

    Timecop.freeze "2017-01-01" do
      put "/v2/content/#{content_id}", params: edition.to_json
      post "/v2/content/#{content_id}/publish", params: { locale: edition["locale"], update_type: "major" }.to_json
    end

    get "/v2/actions/#{content_id}"

    expect(parsed_response).to eql([
      { "action" => "PutContent", "user_uid" => nil, "created_at" => "2017-01-01T00:00:00.000Z" },
      { "action" => "Publish", "user_uid" => nil, "created_at" => "2017-01-01T00:00:00.000Z" },
    ])
  end

  def stub_content_store_calls(base_path)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
  end
end
