ENV['RAILS_ENV']='test'
require 'webmock'
require 'pact/provider/rspec'

WebMock.disable!

Pact.configure do | config |
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
end

Pact.service_provider "Publishing API" do
  honours_pact_with 'GDS API Adapters' do
    if ENV['USE_LOCAL_PACT']
      pact_uri ENV.fetch('GDS_API_PACT_PATH', '../gds-api-adapters/spec/pacts/gds_api_adapters-publishing_api.json')
    else
      base_url = "https://pact-broker.dev.publishing.service.gov.uk/pacts/provider/#{URI.escape(name)}/consumer/#{URI.escape(consumer_name)}"
      version_part = ENV['GDS_API_PACT_VERSION'] ? "versions/#{ENV['GDS_API_PACT_VERSION']}" : 'latest'

      pact_uri "#{base_url}/#{version_part}"
    end
  end
end

Pact.provider_states_for "GDS API Adapters" do
  set_up do
    WebMock.enable!
    WebMock.reset!
    DatabaseCleaner.clean_with :truncation
  end

  tear_down do
    WebMock.disable!
  end

  provider_state "a publish intent exists at /test-intent" do
    set_up do
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('draft-content-store')) + "/content"))
      stub_request(:delete, Plek.find('content-store') + "/publish-intent/test-intent")
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"} )

      # TBD: in theory we should create an event as well
    end
  end

  provider_state "no content exists" do
    set_up do
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('draft-content-store')) + "/content"))
      stub_request(:delete, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/publish-intent"))
        .to_return(status: 404, body: "{}", headers: {"Content-Type" => "application/json"} )
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/publish-intent"))
        .to_return(status: 200, body: "{}", headers: {"Content-Type" => "application/json"} )
    end
  end

  provider_state "/test-item has been reserved by the Publisher application" do
    set_up do
      FactoryGirl.create(:path_reservation, base_path: "/test-item", publishing_app: "publisher")
    end
  end

  provider_state "a content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      draft = FactoryGirl.create(
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

      FactoryGirl.create(:version, target: draft, number: 1)
    end
  end

  provider_state "a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      draft = FactoryGirl.create(:draft_content_item, content_id: "bed722e6-db68-43e5-9079-063f623335a7")
      FactoryGirl.create(:version, target: draft, number: 1)
    end
  end

  provider_state "a French content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      draft = FactoryGirl.create(:draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "fr",
      )
      FactoryGirl.create(:version, target: draft, number: 1)
    end
  end

  provider_state "a published content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do

      live = FactoryGirl.create(:live_content_item, :with_draft, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      FactoryGirl.create(:version, target: live, number: 1)
      FactoryGirl.create(:version, target: live.draft_content_item, number: 1)
    end
  end

  provider_state "a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 which does not have a publishing_app" do
    set_up do
      draft_content_item = FactoryGirl.create(:draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
      )

      draft_content_item.update_columns(publishing_app: nil)

      FactoryGirl.create(:version, target: draft_content_item, number: 1)
    end
  end

  provider_state "organisation links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      link_set = FactoryGirl.create(:link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
      )
      FactoryGirl.create(:version, target: link_set, number: 2)
      FactoryGirl.create(:link, link_set: link_set, link_type: "organisations", target_content_id: "20583132-1619-4c68-af24-77583172c070")
    end
  end

  provider_state "empty links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      link_set = FactoryGirl.create(:link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
      )
      FactoryGirl.create(:version, target: link_set, number: 2)
    end
  end

  provider_state "no links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      # no-op
    end
  end

  provider_state "a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 and locale: fr" do
    set_up do
      draft = FactoryGirl.create(:draft_content_item, content_id: "bed722e6-db68-43e5-9079-063f623335a7", locale: "fr")
      FactoryGirl.create(:version, target: draft, number: 1)
    end
  end

  provider_state "a content item exists in multiple locales with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      english_draft = FactoryGirl.create(:draft_content_item, content_id: "bed722e6-db68-43e5-9079-063f623335a7", locale: "en")
      french_draft = FactoryGirl.create(:draft_content_item, content_id: "bed722e6-db68-43e5-9079-063f623335a7", locale: "fr")
      arabic_draft = FactoryGirl.create(:draft_content_item, content_id: "bed722e6-db68-43e5-9079-063f623335a7", locale: "ar")

      FactoryGirl.create(:version, target: english_draft, number: 1)
      FactoryGirl.create(:version, target: french_draft, number: 1)
      FactoryGirl.create(:version, target: arabic_draft, number: 1)
    end
  end

  provider_state "the content item bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      draft = FactoryGirl.create(:draft_content_item, content_id: "bed722e6-db68-43e5-9079-063f623335a7")
      FactoryGirl.create(:version, target: draft, number: 3)

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("content-store")) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("draft-content-store")) + "/content"))
    end
  end

  provider_state "the linkset for bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      draft = FactoryGirl.create(:draft_content_item, content_id: "bed722e6-db68-43e5-9079-063f623335a7")
      FactoryGirl.create(:version, target: draft, number: 1)

      linkset = FactoryGirl.create(:link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
      )

      FactoryGirl.create(:version, target: linkset, number: 3)

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("content-store")) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("draft-content-store")) + "/content"))
    end
  end

  provider_state "there is content with format 'topic'" do
    set_up do
      FactoryGirl.create(:draft_content_item, title: 'Content Item A', base_path: '/a-base-path', format: 'topic')
      FactoryGirl.create(:draft_content_item, title: 'Content Item B', base_path: '/another-base-path', format: 'topic')
    end
  end
end
