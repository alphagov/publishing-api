require "rails_helper"
require "govuk_schemas"

RSpec.describe "Message queue publishing" do
  it "puts the correct message on the queue" do
    base_path = "/#{SecureRandom.hex}"

    stub_content_store_calls(base_path)

    content_item = generate_random_content_item(base_path)

    put "/v2/content/#{content_id}", params: content_item.to_json

    expect(response).to be_ok

    post "/v2/content/#{content_id}/publish", params: { update_type: "major", locale: content_item["locale"] }.to_json

    expect(response).to be_ok

    ensure_message_queue_payload_validates_against_notification_schema
  end

  def stub_content_store_calls(base_path)
    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
  end

  def generate_random_content_item(base_path)
    GovukSchemas::RandomExample.for_schema(publisher_schema: "placeholder").merge_and_validate(
      base_path: base_path,
      rendering_app: "something", # schema do not enforce a "dns-hostname" pattern yet
      publishing_app: "something", # schema do not enforce a "dns-hostname" pattern yet
      redirects: [], # is not validated in schemas yet
      routes: [
        { path: base_path, type: "prefix" } # hard to do in schemas
      ]
    )
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
