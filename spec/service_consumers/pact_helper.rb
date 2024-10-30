ENV["RAILS_ENV"] = "test"
ENV["PACT_DO_NOT_TRACK"] = "true"
require "active_support"
require "webmock"
require "pact/provider/rspec"
require "factory_bot_rails"

WebMock.disable!

Pact.configure do |config|
  config.reports_dir = "spec/reports/pacts"
  config.include WebMock::API
  config.include WebMock::Matchers
  config.include FactoryBot::Syntax::Methods
end

def url_encode(str)
  ERB::Util.url_encode(str)
end

Pact.service_provider "Publishing API" do
  honours_pact_with "GDS API Adapters" do
    if ENV["PACT_URI"]
      pact_uri(ENV["PACT_URI"])
    else
      base_url = ENV.fetch("PACT_BROKER_BASE_URL", "https://govuk-pact-broker-6991351eca05.herokuapp.com")
      url = "#{base_url}/pacts/provider/#{url_encode(name)}/consumer/#{url_encode(consumer_name)}"

      pact_uri "#{url}/versions/#{url_encode(ENV.fetch('PACT_CONSUMER_VERSION', 'master'))}"
    end
  end
end

Pact.provider_states_for "GDS API Adapters" do
  set_up do
    WebMock.enable!
    WebMock.reset!
    DatabaseCleaner.clean_with :truncation
    GDS::SSO.test_user = create(
      :user,
      permissions: %w[signin view_all],
    )
  end

  tear_down do
    WebMock.disable!
  end

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

  provider_state "/test-item has been reserved by the Publisher application" do
    set_up do
      create(:path_reservation, base_path: "/test-item", publishing_app: "publisher")
    end
  end

  provider_state "a content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(
        :draft_edition,
        base_path: "/robots.txt",
        document:,
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
            type: "exact",
          },
        ],
      )
    end
  end

  provider_state "a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(:draft_edition, document:)
    end
  end

  provider_state "a draft content item exists with content_id bed722e6-db68-43e5-9079-063f623335a7 with a blocking live item at the same path" do
    set_up do
      create(
        :live_edition,
        document: create(:document),
        base_path: "/blocking_path",
      )

      draft_document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(
        :draft_edition,
        document: draft_document,
        base_path: "/blocking_path",
      )
    end
  end

  provider_state "a French content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      document = create(
        :document,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "fr",
      )

      create(:draft_edition, document:)
    end
  end

  provider_state "a published content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(:live_edition, document:)
    end
  end

  provider_state "a published content item exists with a draft edition for content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(:live_edition, :with_draft, document:)
    end
  end

  provider_state "an unpublished content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(:unpublished_edition, document:)
    end
  end

  provider_state "organisation links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      link_set = create(
        :link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 2,
      )

      document = create(:document, content_id: "20583132-1619-4c68-af24-77583172c070")
      create(:edition, document:)
      create(:link, link_set:, link_type: "organisations", target_content_id: document.content_id)
    end
  end

  provider_state "empty links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      create(
        :link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 2,
      )
    end
  end

  provider_state "taxon links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      link_set = create(
        :link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 2,
      )

      taxon = create(:document, content_id: "20583132-1619-4c68-af24-77583172c070")
      create(:edition, document: taxon)
      create(:link, link_set:, link_type: "taxons", target_content_id: taxon.content_id)
    end
  end

  provider_state "no links exist for content_id bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      # no-op
    end
  end

  provider_state "a draft content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 and locale: fr" do
    set_up do
      document = create(
        :document,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        locale: "fr",
      )

      create(:draft_edition, document:)
    end
  end

  provider_state "a content item exists in multiple locales with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      en_doc = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")
      fr_doc = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7", locale: "fr")
      ar_doc = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7", locale: "ar")

      create(
        :draft_edition,
        document: en_doc,
        document_type: "taxon",
        schema_name: "taxon",
        public_updated_at: "2015-01-03",
        user_facing_version: 1,
      )

      create(
        :draft_edition,
        document: fr_doc,
        document_type: "taxon",
        schema_name: "taxon",
        public_updated_at: "2015-01-02",
        user_facing_version: 1,
      )

      create(
        :draft_edition,
        document: ar_doc,
        document_type: "taxon",
        schema_name: "taxon",
        public_updated_at: "2015-01-01",
        user_facing_version: 1,
      )
    end
  end

  provider_state "a content item exists in with a superseded version with content_id: bed722e6-db68-43e5-9079-063f623335a7" do
    set_up do
      document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(
        :superseded_edition,
        document:,
        document_type: "taxon",
        schema_name: "taxon",
        public_updated_at: "2015-01-03",
        user_facing_version: 1,
      )

      create(
        :live_edition,
        document:,
        document_type: "taxon",
        schema_name: "taxon",
        public_updated_at: "2015-01-03",
        user_facing_version: 2,
      )
    end
  end

  provider_state "the content item bed722e6-db68-43e5-9079-063f623335a7 is at lock version 3" do
    set_up do
      document = create(
        :document,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 3,
      )

      create(:draft_edition, document:)

      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/content"))
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('draft-content-store'))}/content"))
    end
  end

  provider_state "the linkset for bed722e6-db68-43e5-9079-063f623335a7 is at lock version 3" do
    set_up do
      document = create(
        :document,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 1,
      )

      create(:draft_edition, document:)

      create(
        :link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 3,
      )

      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/content"))
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('draft-content-store'))}/content"))
    end
  end

  provider_state "there are four content items with document_type 'taxon'" do
    set_up do
      (1..4).each do |index|
        create(
          :live_edition,
          title: "title_#{index}",
          document: create(:document),
          base_path: "/path_#{index}",
          document_type: "taxon",
          public_updated_at: Time.zone.local(2018, 12 - index, 1, 12, 0, 0),
        )
      end
    end
  end

  provider_state "there is content with document_type 'taxon'" do
    set_up do
      document_a = create(
        :document,
        content_id: "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa",
      )

      create(
        :draft_edition,
        title: "Content Item A",
        document: document_a,
        base_path: "/a-base-path",
        document_type: "taxon",
        schema_name: "taxon",
        public_updated_at: "2015-01-02",
        details: {
          internal_name: "an internal name",
        },
      )

      document_b = create(
        :document,
        content_id: "bbbbbbbb-bbbb-2bbb-bbbb-bbbbbbbbbbbb",
      )

      create(
        :live_edition,
        title: "Content Item B",
        document: document_b,
        base_path: "/another-base-path",
        public_updated_at: "2015-01-01",
        document_type: "taxon",
        schema_name: "taxon",
      )
    end
  end
  provider_state "there are two link changes with a link_type of 'taxons'" do
    set_up do
      Timecop.freeze("2017-01-01 09:00:00.1") do
        document_a1 = build(:document, content_id: "aaaaaaaa-aaaa-1aaa-aaaa-aaaaaaaaaaaa")
        document_a2 = build(:document, content_id: "aaaaaaaa-aaaa-2aaa-aaaa-aaaaaaaaaaaa")
        document_b1 = build(:document, content_id: "bbbbbbbb-bbbb-1bbb-bbbb-bbbbbbbbbbbb")
        document_b2 = build(:document, content_id: "bbbbbbbb-bbbb-2bbb-bbbb-bbbbbbbbbbbb")

        action1 = create(:action, user_uid: "11111111-1111-1111-1111-111111111111")
        action2 = create(:action, user_uid: "22222222-2222-2222-2222-222222222222")

        create(
          :edition,
          title: "Edition Title A1",
          base_path: "/base/path/a1",
          document: document_a1,
        )
        create(
          :edition,
          title: "Edition Title A2",
          base_path: "/base/path/a2",
          document: document_a2,
        )
        create(
          :edition,
          title: "Edition Title B1",
          base_path: "/base/path/b1",
          document: document_b1,
        )
        create(
          :edition,
          title: "Edition Title B2",
          base_path: "/base/path/b2",
          document: document_b2,
        )

        create(
          :link_change,
          source_content_id: document_a1.content_id,
          target_content_id: document_b1.content_id,
          action: action1,
          change: "add",
        )
        create(
          :link_change,
          source_content_id: document_a2.content_id,
          target_content_id: document_b2.content_id,
          action: action2,
          change: "remove",
        )
      end
    end
  end
  provider_state "there is content with document_type 'taxon' for multiple publishing apps" do
    set_up do
      document_a = create(:document)
      document_b = create(:document)
      document_c = create(:document)

      create(
        :draft_edition,
        document: document_a,
        title: "Content Item A",
        base_path: "/a-base-path",
        document_type: "taxon",
        schema_name: "taxon",
      )

      create(
        :draft_edition,
        document: document_b,
        title: "Content Item B",
        base_path: "/another-base-path",
        document_type: "taxon",
        schema_name: "taxon",
      )

      create(
        :draft_edition,
        document: document_c,
        title: "Content Item C",
        base_path: "/yet-another-base-path",
        document_type: "taxon",
        schema_name: "taxon",
        publishing_app: "whitehall",
      )
    end
  end

  provider_state "there are two documents with a 'taxon' link to another document" do
    set_up do
      content_id1 = "6cb2cf8c-670f-4de3-97d5-6ad9114581c7"
      content_id2 = "08dfd5c3-d935-4e81-88fd-cfe65b78893d"
      content_id3 = "e2961462-bc37-48e9-bb98-c981ef1a2d59"

      document1 = create(:document, content_id: content_id1)
      document2 = create(:document, content_id: content_id2)
      document3 = create(:document, content_id: content_id3)

      create(
        :live_edition,
        document: document1,
        user_facing_version: 1,
      )

      create(
        :draft_edition,
        document: document1,
        user_facing_version: 2,
      )

      create(
        :live_edition,
        document: document3,
        base_path: "/item-b",
        public_updated_at: "2015-01-02",
        user_facing_version: 1,
      )

      create(
        :live_edition,
        document: document2,
        base_path: "/item-a",
        public_updated_at: "2015-01-01",
        user_facing_version: 1,
      )

      link_set1 = create(:link_set, content_id: content_id3)
      link_set2 = create(:link_set, content_id: content_id2)

      create(:link, link_set: link_set1, link_type: "taxon", target_content_id: content_id1)
      create(:link, link_set: link_set2, link_type: "taxon", target_content_id: content_id1)
    end
  end

  provider_state "a content item exists with content_id: bed722e6-db68-43e5-9079-063f623335a7 and it has details" do
    set_up do
      document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")

      create(
        :draft_edition,
        document:,
        document_type: "taxon",
        schema_name: "taxon",
        details: { foo: :bar },
      )
    end
  end

  provider_state "the content item bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      document = create(
        :document,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 3,
      )

      create(:draft_edition, document:)

      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/content"))
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('draft-content-store'))}/content"))
    end
  end

  provider_state "the published content item bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      document = create(
        :document,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 3,
      )

      create(:live_edition, document:)

      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/content"))
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('draft-content-store'))}/content"))
    end
  end

  provider_state "the linkset for bed722e6-db68-43e5-9079-063f623335a7 is at version 3" do
    set_up do
      document = create(
        :document,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 1,
      )

      create(:draft_edition, document:)

      create(
        :link_set,
        content_id: "bed722e6-db68-43e5-9079-063f623335a7",
        stale_lock_version: 3,
      )

      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('content-store'))}/content"))
      stub_request(:put, Regexp.new("\\A#{Regexp.escape(Plek.find('draft-content-store'))}/content"))
    end
  end

  provider_state "there are live content items with base_paths /foo and /bar" do
    set_up do
      document1 = create(:document, content_id: "08f86d00-e95f-492f-af1d-470c5ba4752e")

      create(:live_edition, base_path: "/foo", document: document1)

      document2 = create(:document, content_id: "ca6c58a6-fb9d-479d-b3e6-74908781cb18")

      create(:live_edition, base_path: "/bar", document: document2)
    end
  end

  provider_state "there is a draft content item with base_path /foo" do
    set_up do
      document = create(:document, content_id: "cbb460a7-60de-4a74-b5be-0b27c6d6af9b")

      create(:draft_edition, base_path: "/foo", document:)
    end
  end

  provider_state "there are 4 live content items with fixed updated timestamps" do
    set_up do
      document1 = create(:document, content_id: "bd50a6d9-f03d-4ccf-94aa-ad79579990a9")
      document2 = create(:document, content_id: "989033fe-252a-4e69-976d-5c0059bca949")
      document3 = create(:document, content_id: "271d4270-9186-4d60-b2ca-1d7dae7e0f73")
      document4 = create(:document, content_id: "638af19c-27fc-4cc9-a914-4cca49028688")

      create(:live_edition, base_path: "/1", document: document1, updated_at: "2017-01-01T00:00:00Z", published_at: "2017-01-01T00:00:00Z")
      create(:live_edition, base_path: "/2", document: document2, updated_at: "2017-02-01T00:00:00Z", published_at: "2017-02-01T00:00:00Z")
      create(:live_edition, base_path: "/3", document: document3, updated_at: "2017-03-01T00:00:00Z", published_at: "2017-03-01T00:00:00Z")
      create(:live_edition, base_path: "/4", document: document4, updated_at: "2017-04-01T00:00:00Z", published_at: "2017-04-01T00:00:00Z")
    end
  end

  provider_state "a content item exists (content_id: d66d6552-2627-4451-9dbc-cadbbd2005a1) that embeds the reusable content (content_id: bed722e6-db68-43e5-9079-063f623335a7)" do
    set_up do
      reusable_document = create(:document, content_id: "bed722e6-db68-43e5-9079-063f623335a7")
      reusable_edition = create(:live_edition, document: reusable_document)

      document = create(:document, content_id: "d66d6552-2627-4451-9dbc-cadbbd2005a1")
      live_edition_with_embedded_edition = create(:live_edition,
                                                  :with_embedded_content,
                                                  document:,
                                                  embedded_content_id: reusable_edition.content_id,
                                                  title: "foo",
                                                  base_path: "/foo",
                                                  document_type: "publication")

      organisation_document = create(:document, content_id: "d1e7d343-9844-4246-a469-1fa4640e12ad")
      primary_publishing_organisation = create(:live_edition,
                                               document: organisation_document,
                                               title: "bar",
                                               document_type: "organisation",
                                               schema_name: "organisation",
                                               base_path: "/bar")
      create(
        :link,
        edition: live_edition_with_embedded_edition,
        link_type: :primary_publishing_organisation,
        link_set: nil,
        position: 0,
        target_content_id: primary_publishing_organisation.content_id,
      )
    end

    provider_state "a published content item exists with base_path /my-document" do
      set_up do
        document = create(:document, content_id: "19ad249e-7ac4-4aa4-8ab4-b6c5f381c043")

        create(:live_edition,
               document:,
               base_path: "/my-document",
               title: "My document")
      end
    end
  end
end
