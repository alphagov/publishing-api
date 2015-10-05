module RequestHelpers
  module Mocks
    extend self

    def base_path
      "/vat-rates"
    end

    def content_id
      "582e1d3f-690e-4115-a948-e05b3c6b3d88"
    end

    def content_item_without_access_limiting
      {
        content_id: content_id,
        title: "VAT rates",
        description: "VAT rates for goods and services",
        format: "guide",
        need_ids: ["100123", "100124"],
        public_updated_at: "2014-05-14T13:00:06Z",
        publishing_app: "mainstream_publisher",
        rendering_app: "mainstream_frontend",
        locale: "en",
        phase: "beta",
        details: {
          body: "<p>Something about VAT</p>\n",
        },
        routes: [
          {
            path: "/vat-rates",
            type: "exact",
          }
        ],
        redirects: [
          {
            path: "/old-vat-rates",
            type: "exact",
            destination: "/vat-rates",
          }
        ],
        update_type: "major",
      }.merge(links_attributes)
    end

    def links_attributes
      {
        content_id: content_id,
        links: {
          organisations: ["f17250b0-7540-0131-f036-005056030221"]
        },
      }
    end

    def content_item_with_access_limiting
      content_item_without_access_limiting.merge(
        access_limited: {
          users: [
            "f17250b0-7540-0131-f036-005056030202",
            "74c7d700-5b4a-0131-7a8e-005056030037",
          ],
        },
      )
    end

    def redirect_content_item
      {
        base_path: "/crb-checks",
        format: "redirect",
        public_updated_at: "2014-05-14T13:00:06Z",
        publishing_app: "publisher",
        redirects: [
          {
            path: "/crb-checks",
            type: "prefix",
            destination: "/dbs-checks"
          },
        ],
        update_type: "major",
      }
    end

    def v2_content_item
      content_item_with_access_limiting
        .except(:links)
        .merge(base_path: base_path)
    end
  end
end

RSpec.configuration.include RequestHelpers::Mocks, :type => :request
