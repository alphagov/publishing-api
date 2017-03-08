require "rails_helper"

RSpec.describe "Message queue publishing" do
  include RandomContentHelpers

  it "puts the correct message on the queue" do
    base_path = "/#{SecureRandom.hex}"
    stub_content_store_calls(base_path)
    edition = generate_random_edition(base_path)

    put "/v2/content/#{content_id}", params: edition.to_json
    expect(response).to be_ok, random_content_failure_message(response, edition)

    post "/v2/content/#{content_id}/publish", params: { locale: edition["locale"], update_type: "major" }.to_json
    expect(response).to be_ok, random_content_failure_message(response, edition)

    ensure_message_queue_payload_validates_against_notification_schema
  end

  def stub_content_store_calls(base_path)
    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
  end

  def ensure_message_queue_payload_validates_against_notification_schema
    expect(PublishingAPI.service(:queue_publisher)).to have_received(:send_message) do |payload|
      errors = JSON::Validator.fully_validate(
        GovukSchemas::Schema.find(notification_schema: "placeholder"),
        payload,
        errors_as_objects: true,
      )
      expect(errors).to eql([])
    end
  end
end
