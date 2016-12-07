require "rails_helper"

RSpec.describe "GET /v2/expanded-links/:id", type: :request do
  let(:translations) {
    [
      {
        "analytics_identifier" => "GDS01",
        "api_path" => "/api/content/some-path",
        "base_path" => "/some-path",
        "content_id" => "10529c0d-f4b3-4c7d-9589-35ba6a6d1a12",
        "description" => "Some description",
        "locale" => "en",
        "document_type" => "placeholder",
        "schema_name" => "placeholder",
        "public_updated_at" => "2014-05-14T13:00:06Z",
        "title" => "Some title",
        "withdrawn" => false,
      }
    ]
  }

  let(:content_item) {
    FactoryGirl.create(:content_item,
      state: "published",
      document_type: "placeholder",
      schema_name: "placeholder",
      title: "Some title",
      base_path: "/some-path",
      description: "Some description",
      content_id: "10529c0d-f4b3-4c7d-9589-35ba6a6d1a12"
    )
  }

  it "returns expanded links" do
    organisation = FactoryGirl.create(:content_item,
      state: "published",
      document_type: "organisation",
      schema_name: "organisation",
      base_path: "/my-super-org",
      content_id: "9b5ae6f5-f127-4843-9333-c157a404dd2d",
    )

    link_set = FactoryGirl.create(:link_set,
      content_id: content_item.content_id,
    )

    FactoryGirl.create(:link, link_set: link_set, target_content_id: organisation.content_id, link_type: 'organisations')

    get "/v2/expanded-links/#{content_item.content_id}"

    expect(parsed_response).to eql(
      "version" => 0,
      "content_id" => content_item.content_id,
      "expanded_links" => {
        "organisations" => [
          {
            "analytics_identifier" => "GDS01",
            "api_path" => "/api/content/my-super-org",
            "base_path" => "/my-super-org",
            "content_id" => "9b5ae6f5-f127-4843-9333-c157a404dd2d",
            "schema_name" => "organisation",
            "document_type" => "organisation",
            "description" => "VAT rates for goods and services",
            "locale" => "en",
            "public_updated_at" => "2014-05-14T13:00:06Z",
            "title" => "VAT rates",
            "withdrawn" => false,
            "links" => {},
            "details" => { "body" => "<p>Something about VAT</p>\n" },
          }
        ],
        "available_translations" => translations,
      }
    )
  end

  it "returns only translations if there are no links" do
    link_set = FactoryGirl.create(:link_set,
      content_id: content_item.content_id,
    )

    get "/v2/expanded-links/#{link_set.content_id}"

    expect(parsed_response).to eql(
      "version" => 0,
      "content_id" => content_item.content_id,
      "expanded_links" => {
        "available_translations" => translations,
      },
    )
  end

  it "returns a version if the link set has a version" do
    link_set = FactoryGirl.create(:link_set,
      content_id: content_item.content_id,
    )

    FactoryGirl.create(:lock_version, target: link_set, number: 11)

    get "/v2/expanded-links/#{link_set.content_id}"

    expect(parsed_response).to eql(
      "version" => 11,
      "content_id" => content_item.content_id,
      "expanded_links" => {
        "available_translations" => translations,
      },
    )
  end

  it "returns 404 if the link set is not found" do
    get "/v2/expanded-links/I-DO-NOT-EXIST"

    expect(parsed_response).to eql(
      "error" => {
        "code" => 404,
        "message" => "Could not find link set with content_id: I-DO-NOT-EXIST",
      }
    )
  end
end
