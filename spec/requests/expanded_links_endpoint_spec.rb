require "rails_helper"

RSpec.describe "GET /v2/expanded-links/:id", type: :request do
  it "returns expanded links" do
    organisation = create(:content_item,
      state: "published",
      format: "organisation",
      base_path: "/my-super-org",
      content_id: "9b5ae6f5-f127-4843-9333-c157a404dd2d",
    )

    content_item = create(:content_item,
      state: "published",
      format: "placeholder",
      title: "Some title",
    )

    link_set = create(:link_set,
      content_id: content_item.content_id,
    )

    create(:link, link_set: link_set, target_content_id: organisation.content_id, link_type: 'organisations')

    get "/v2/expanded-links/#{content_item.content_id}"

    expect(parsed_response).to eql({
      "version" => 0,
      "content_id" => content_item.content_id,
      "expanded_links" => {
        "organisations" => [
          {
            "analytics_identifier" => "GDS01",
            "api_url" => "http://www.dev.gov.uk/api/content/my-super-org",
            "base_path" => "/my-super-org",
            "content_id" => "9b5ae6f5-f127-4843-9333-c157a404dd2d",
            "description" => "VAT rates for goods and services",
            "locale" => "en",
            "title" => "VAT rates",
            "web_url" => "http://www.dev.gov.uk/my-super-org",
            "expanded_links" => {}
          }
        ]
      }
    })
  end

  it "returns empty expanded links if there are no links" do
    content_item = create(:content_item,
      state: "published",
      format: "placeholder",
      title: "Some title",
    )

    link_set = create(:link_set,
      content_id: content_item.content_id,
    )

    get "/v2/expanded-links/#{link_set.content_id}"

    expect(parsed_response).to eql({
      "version" => 0,
      "content_id" => content_item.content_id,
      "expanded_links" => {}
    })
  end

  it "returns a version if the link set has a version" do
    content_item = create(:content_item,
      state: "published",
      format: "placeholder",
      title: "Some title",
    )

    link_set = create(:link_set,
      content_id: content_item.content_id,
    )

    create(:lock_version, target: link_set, number: 11)

    get "/v2/expanded-links/#{link_set.content_id}"

    expect(parsed_response).to eql({
      "version" => 11,
      "content_id" => content_item.content_id,
      "expanded_links" => {}
    })
  end
end
