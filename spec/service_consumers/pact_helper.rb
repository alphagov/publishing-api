ENV['RAILS_ENV'] = 'test'
require 'webmock'
require 'pact/provider/rspec'

WebMock.disable!

Pact.configure do |config|
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
    GDS::SSO.test_user = FactoryGirl.create(:user,
      permissions: %w(signin view_all),
    )
  end

  tear_down do
    WebMock.disable!
  end

  provider_state "a publish intent exists at /test-intent" do
    set_up do
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('draft-content-store')) + "/content"))
      stub_request(:delete, Plek.find('content-store') + "/publish-intent/test-intent")
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })

      # TBD: in theory we should create an event as well
    end
  end

  provider_state "no content exists" do
    set_up do
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('draft-content-store')) + "/content"))
      stub_request(:delete, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/publish-intent"))
        .to_return(status: 404, body: "{}", headers: { "Content-Type" => "application/json" })
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find('content-store')) + "/publish-intent"))
        .to_return(status: 200, body: "{}", headers: { "Content-Type" => "application/json" })
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
        document_type: "special_route",
        schema_name: "special_route",
        public_updated_at: "2015-07-30T13:58:11+00:00",
        publishing_app: "static",
        rendering_app: "static",
        routes: [
          {
            path: "/robots.txt",
            type: "exact"
          },
        ],
        lock_version: 1
      )
    end
  end

  provider_state "a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      draft = FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        lock_version: 1
      )
    end
  end

  provider_state "a draft content item exists with content_id bed722e6-db68-43e5-9079-063f623335a7 with a blocking live item at the same path" do
    set_up do
      live = FactoryGirl.create(
        :live_content_item,
        base_path: "/blocking_path",
        lock_version: 1,
      )
      draft = FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        base_path: "/blocking_path",
        lock_version: 1,
      )
    end
  end

  provider_state "a French content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      draft = FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "fr",
        lock_version: 1,
      )
    end
  end

  provider_state "a published content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      live = FactoryGirl.create(
        :live_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        lock_version: 1,
      )
    end
  end

  provider_state "an unpublished content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      FactoryGirl.create(
        :unpublished_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7"
      )
    end
  end

  provider_state "organisation links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      link_set = FactoryGirl.create(:link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 2,
      )
      linked_organisation = FactoryGirl.create(:content_item, content_id: "20583132-1619-4c68-af24-77583172c070")
      FactoryGirl.create(:link, link_set: link_set, link_type: "organisations", target_content_id: linked_organisation.content_id)
    end
  end

  provider_state "empty links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      link_set = FactoryGirl.create(:link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 2,
      )
    end
  end

  provider_state "no links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      # no-op
    end
  end

  provider_state "a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 and locale: fr" do
    set_up do
      draft = FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "fr",
        lock_version: 1,
      )
    end
  end

  provider_state "a content item exists in multiple locales with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "en",
        document_type: "topic",
        schema_name: "topic",
        public_updated_at: '2015-01-03',
        user_facing_version: 1,
      )
      FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "fr",
        document_type: "topic",
        schema_name: "topic",
        public_updated_at: '2015-01-02',
        user_facing_version: 1,
      )
      FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "ar",
        document_type: "topic",
        schema_name: "topic",
        public_updated_at: '2015-01-01',
        user_facing_version: 1,
      )
    end
  end

  provider_state "a content item exists in with a superseded version with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      FactoryGirl.create(:superseded_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "en",
        document_type: "topic",
        schema_name: "topic",
        public_updated_at: '2015-01-03',
        user_facing_version: 1,
      )

      FactoryGirl.create(:live_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "en",
        document_type: "topic",
        schema_name: "topic",
        public_updated_at: '2015-01-03',
        user_facing_version: 2,
      )
    end
  end

  provider_state "the content item bed722e6-db68-43e5-9079-063f623335a7 is at lock version 3" do
    set_up do
      draft = FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        lock_version: 3,
      )

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("content-store")) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("draft-content-store")) + "/content"))
    end
  end

  provider_state "the linkset for bed722e6-db68-43e5-9079-063f623335a7 is at lock version 3" do
    set_up do
      draft = FactoryGirl.create(
        :draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        lock_version: 1,
      )

      linkset = FactoryGirl.create(:link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 3,
      )

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("content-store")) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("draft-content-store")) + "/content"))
    end
  end

  provider_state "there is content with document_type 'topic'" do
    set_up do
      FactoryGirl.create(:draft_content_item,
        title: 'Content Item A',
        content_id: 'aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa',
        base_path: '/a-base-path',
        document_type: "topic",
        schema_name: "topic",
        public_updated_at: '2015-01-02',
        details: {
          internal_name: "an internal name",
        },
      )

      FactoryGirl.create(:live_content_item,
        title: 'Content Item B',
        content_id: 'bbbbbbbb-bbbb-2bbb-bbbb-bbbbbbbbbbbb',
        base_path: '/another-base-path',
        public_updated_at: '2015-01-01',
        document_type: "topic",
        schema_name: "topic",
      )
    end
  end

  provider_state "there is content with document_type 'topic' for multiple publishing apps" do
    set_up do
      content_item = FactoryGirl.create(
        :draft_content_item,
        title: 'Content Item A',
        base_path: '/a-base-path',
        document_type: "topic",
        schema_name: "topic",
        lock_version: 1,
      )

      content_item = FactoryGirl.create(
        :draft_content_item,
        title: 'Content Item B',
        base_path: '/another-base-path',
        document_type: "topic",
        schema_name: "topic",
        lock_version: 1,
      )

      content_item = FactoryGirl.create(
        :draft_content_item,
        title: 'Content Item C',
        base_path: '/yet-another-base-path',
        document_type: "topic",
        schema_name: "topic",
        publishing_app: 'whitehall',
        lock_version: 1,
      )
    end
  end

  provider_state "there are two documents with a 'topic' link to another document" do
    set_up do
      content_id1 = "6cb2cf8c-670f-4de3-97d5-6ad9114581c7"
      content_id2 = "08dfd5c3-d935-4e81-88fd-cfe65b78893d"
      content_id3 = "e2961462-bc37-48e9-bb98-c981ef1a2d59"

      FactoryGirl.create(
        :live_content_item,
        content_id: content_id1,
        user_facing_version: 1,
      )
      FactoryGirl.create(
        :draft_content_item,
        content_id: content_id1,
        user_facing_version: 2
      )

      FactoryGirl.create(
        :live_content_item,
        content_id: content_id3,
        base_path: '/item-b',
        public_updated_at: '2015-01-02',
        user_facing_version: 1,
      )

      FactoryGirl.create(
        :live_content_item,
        content_id: content_id2,
        base_path: '/item-a',
        public_updated_at: '2015-01-01',
        user_facing_version: 1,
      )

      link_set1 = FactoryGirl.create(:link_set, content_id: content_id3)
      link_set2 = FactoryGirl.create(:link_set, content_id: content_id2)

      FactoryGirl.create(:link, link_set: link_set1, link_type: "topic", target_content_id: content_id1)
      FactoryGirl.create(:link, link_set: link_set2, link_type: "topic", target_content_id: content_id1)
    end
  end

  provider_state "a content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 and it has details" do
    set_up do
      FactoryGirl.create(
        :draft_content_item,
        content_id: 'bed722e6-db68-43e5-9079-063f623335a7',
        document_type: "topic",
        schema_name: "topic",
        details: { foo: :bar },
      )
    end
  end

  provider_state "the content item bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      FactoryGirl.create(:draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        lock_version: 3
      )

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("content-store")) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("draft-content-store")) + "/content"))
    end
  end

  provider_state "the published content item bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      FactoryGirl.create(:live_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        lock_version: 3
      )

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("content-store")) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("draft-content-store")) + "/content"))
    end
  end

  provider_state "the linkset for bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      FactoryGirl.create(:draft_content_item,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        lock_version: 1
      )

      link_set = FactoryGirl.create(:link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 3,
      )

      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("content-store")) + "/content"))
      stub_request(:put, Regexp.new('\A' + Regexp.escape(Plek.find("draft-content-store")) + "/content"))
    end
  end

  provider_state "there are live content items with base_paths /foo and /bar" do
    set_up do
      FactoryGirl.create(
        :live_content_item,
        base_path: '/foo',
        content_id: '08f86d00-e95f-492f-af1d-470c5ba4752e',
      )

      FactoryGirl.create(
        :live_content_item,
        base_path: '/bar',
        content_id: 'ca6c58a6-fb9d-479d-b3e6-74908781cb18',
      )
    end
  end
end
