module RequestHelpers
  module Mocks
    extend self

    def api_path
      "/api/content" + base_path
    end

    def base_path
      "/vat-rates"
    end

    def content_id
      "582e1d3f-690e-4115-a948-e05b3c6b3d88"
    end

    def content_item_params
      {
        analytics_identifier: "GDS01",
        base_path: base_path,
        content_id: content_id,
        description: "VAT rates for goods and services",
        document_type: "services_and_information",
        schema_name: "generic",
        first_published_at: Time.zone.parse("2014-01-02T03:04:05.000Z"),
        public_updated_at: Time.zone.parse("2014-05-14T13:00:06.000Z"),
        publishing_app: "publisher",
        redirects: [],
        rendering_app: "frontend",
        locale: "en",
        phase: "beta",
        details: {},
        routes: [
          {
            path: base_path,
            type: "exact",
          },
        ],
        update_type: "major",
        title: "VAT rates",
        expanded_links: {
          available_translations: available_translations,
        },
      }
    end

    def access_limit_params
      {
        users: %w[
          bf3e4b4f-f02d-4658-95a7-df7c74cd0f50
          74c7d700-5b4a-0131-7a8e-005056030037
        ],
        auth_bypass_ids: [],
      }
    end

    def patch_links_attributes
      {
        content_id: content_id,
        links: {
          organisations: %w[30986e26-f504-4e14-a93f-a9593c34a8d9],
        },
      }
    end

    def available_translations
      [
        {
          analytics_identifier: "GDS01",
          base_path: "/vat-rates",
          content_id: content_id,
          description: "VAT rates for goods and services",
          document_type: "services_and_information",
          locale: "en",
          public_updated_at: Time.zone.parse("2014-05-14T13:00:06Z"),
          schema_name: "generic",
          title: "VAT rates",
          api_path: "/api/content/vat-rates",
          withdrawn: false,
        },
      ]
    end

    def v2_content_item
      content_item_params
        .except(:expanded_links)
        .merge(base_path: base_path)
    end
  end
end

RSpec.configuration.include RequestHelpers::Mocks, type: :request
