RSpec.describe "Randomised content" do
  include RandomContentHelpers

  50.times do |i|
    it "it can publish randomly generated content #{i + 1}/50" do
      base_path = "/#{SecureRandom.hex}"
      stub_content_store_calls(base_path)
      edition = generate_random_edition(base_path)

      put "/v2/content/#{content_id}", params: edition.to_json

      expect(response).to be_ok, random_content_failure_message(response, edition)

      params = edition["locale"] ? { locale: edition["locale"] } : {}
      post "/v2/content/#{content_id}/publish", params: params.to_json

      expect(response).to be_ok, random_content_failure_message(response, edition)
    end
  end

  def stub_content_store_calls(base_path)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
  end
end
