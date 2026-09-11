RSpec.describe "Verify pact for GDS API Adapters", :pact_v2 do
  Pact::V2.configure do |config|
    config.before_provider_state_setup do
      DatabaseCleaner.clean_with :truncation
      GDS::SSO.test_user = FactoryBot.create(:user, permissions: %w[signin view_all])
    end
  end

  http_pact_provider "Publishing API", opts: {
    http_port: 9292,
    pact_uri: ENV["PACT_URI"],
    broker_url: ENV.fetch("PACT_BROKER_BASE_URL", "https://govuk-pact-broker-6991351eca05.herokuapp.com"),
    consumer_name: "GDS API Adapters",
    consumer_version_selectors: [
      { branch: ENV.fetch("PACT_CONSUMER_VERSION", "branch-main").delete_prefix("branch-") },
    ],
    log_level: :info,
    fail_if_no_pacts_found: true,
  }

  provider_state "a publish intent exists at /test-intent" do
    set_up do
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/content"))
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('draft-content-store'))}/content"))
      stub_request(:delete, "#{Plek.find('content-store')}/publish-intent/test-intent")
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      # TBD: in theory we should create an event as well
    end
  end

  provider_state "there are publisher schemas" do
    set_up do
      schemas = {
        "/govuk/publishing-api/content_schemas/dist/formats/email_address/publisher_v2/schema.json": {
          type: "object",
          required: %w[a],
          properties: {
            email_address: { "some" => "schema" },
          },
        },
        "/govuk/publishing-api/content_schemas/dist/formats/tax_license/publisher_v2/schema.json": {
          type: "object",
          required: %w[a],
          properties: {
            tax_license: { "another" => "schema" },
          },
        },
      }

      allow(GovukSchemas::Schema)
        .to receive(:all)
        .with(schema_type: "publisher")
        .and_return(schemas)
    end
  end

  provider_state "there is a schema for an email_address" do
    set_up do
      email_address_schema = {
        "/govuk/publishing-api/content_schemas/dist/formats/email_address/publisher_v2/schema.json": {
          type: "object",
          required: %w[a],
          properties: {
            email_address: { "some" => "schema" },
          },
        },
      }

      allow(GovukSchemas::Schema)
        .to receive(:find)
        .with(publisher_schema: "email_address")
        .and_return(email_address_schema)
    end
  end

  provider_state "there is not a schema for an email_address" do
    set_up do
      allow(GovukSchemas::Schema)
        .to receive(:find)
        .with(publisher_schema: "email_address")
        .and_raise(Errno::ENOENT)
    end
  end

  provider_state "no content exists" do
    set_up do
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/content"))
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('draft-content-store'))}/content"))
      stub_request(:delete, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/publish-intent"))
        .to_return(status: 404, body: "{}", headers: { "Content-Type" => "application/json" })
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/publish-intent"))
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
    end
  end
end
