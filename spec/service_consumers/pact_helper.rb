ENV['RAILS_ENV']='test'
require 'webmock'
require 'pact/provider/rspec'
require "govuk/client/test_helpers/url_arbiter"

WebMock.disable!

Pact.configure do | config |
  config.reports_dir = "spec/reports/pacts"
  config.include GOVUK::Client::TestHelpers::URLArbiter
  config.include WebMock::API
  config.include WebMock::Matchers
end

Pact.service_provider "Publishing API" do
  honours_pact_with 'GDS API Adapters' do
    pact_uri '../gds-api-adapters/spec/pacts/gds_api_adapters-publishing_api.json'
  end
end

Pact.provider_states_for "GDS API Adapters" do
  set_up do
    WebMock.enable!
    WebMock.reset!
  end

  tear_down do
    WebMock.disable!
  end

  provider_state "a publish intent exists at /test-intent in the live content store" do
    set_up do
      DatabaseCleaner.clean_with :truncation

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('draft-content-store')) + "/content"))
      stub_request(:delete, Plek.find('content-store') + "/publish-intent/test-intent")
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"} )

      # TBD: in theory we should create an event as well
    end
  end

  provider_state "both content stores and the url-arbiter are empty" do
    set_up do
      DatabaseCleaner.clean_with :truncation

      stub_default_url_arbiter_responses
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('draft-content-store')) + "/content"))
      stub_request(:delete, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/publish-intent"))
        .to_return(status: 404, body: "{}", headers: {"Content-Type" => "application/json"} )
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/publish-intent"))
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"} )
    end
  end

  provider_state "/test-item has been reserved in url-arbiter by the Publisher application" do
    set_up do
      url_arbiter_has_registration_for("/test-item", "Publisher")
    end
  end

  provider_state "a content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      DatabaseCleaner.clean_with :truncation

      FactoryGirl.create(
        :draft_content_item,
        base_path: "/robots.txt",
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        title: "Instructions for crawler robots",
        description: "robots.txt provides rules for which parts of GOV.UK are permitted to be crawled by different bots.",
        format: "special_route",
        public_updated_at: "2015-07-30T13:58:11+00:00",
        publishing_app: "static",
        rendering_app: "static",
        routes: [
          {
            path: "/robots.txt",
            type: "exact"
          },
        ],
      )
    end
  end
end
