require "rails_helper"
require "govuk_schemas"

RSpec.describe "Message queue publishing" do
  shared_examples "puts message on queue" do
    it "puts the correct message on the queue" do
      base_path = "/#{SecureRandom.hex}"

      stub_content_store_calls(base_path)

      # FIXME: this without("links") should be removed once Edition links are
      # supported: https://github.com/alphagov/publishing-api/pull/749
      edition = generate_random_edition(base_path, change_note).without("links")

      put "/v2/content/#{content_id}", params: edition.to_json

      expect(response).to be_ok, "failed to put-content a randomly generated edition"

      post "/v2/content/#{content_id}/publish", params: { locale: edition["locale"] }.to_json

      expect(response).to be_ok, "failed to publish a randomly generated edition"

      ensure_message_queue_payload_validates_against_notification_schema
    end
  end

  context "when there is a change note" do
    let(:change_note) { true }
    include_examples "puts message on queue"
  end

  context "when there is not a change note" do
    let(:change_note) { false }
    include_examples "puts message on queue"
  end

  def stub_content_store_calls(base_path)
    allow(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
    stub_request(:put, "http://draft-content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
    stub_request(:put, "http://content-store.dev.gov.uk/content#{base_path}")
      .to_return(status: 200)
  end

  def generate_random_edition(base_path, change_note)
    random = GovukSchemas::RandomExample.for_schema(publisher_schema: "placeholder")

    if change_note
      details = random.payload["details"].merge("change_note" => Faker::Lorem.sentence)
    else
      details = random.payload["details"].except("change_note")
    end

    random.merge_and_validate(
      base_path: base_path,
      details: details,
      rendering_app: "something", # schema do not enforce a "dns-hostname" pattern yet
      publishing_app: "something", # schema do not enforce a "dns-hostname" pattern yet
      redirects: [], # is not validated in schemas yet
      routes: [
        { path: base_path, type: "prefix" } # hard to do in schemas
      ],
      update_type: "major",
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
