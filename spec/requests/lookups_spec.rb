require "rails_helper"

RSpec.describe "POST /lookup-by-base-path", type: :request do
  it "returns content_ids for base_paths" do
    create(:content_item, state: "published", base_path: "/my-page", content_id: "b9b2da0a-ec50-4b0e-b29c-b7cbc8195307")
    create(:content_item, state: "draft", base_path: "/my-page", content_id: "f7cdb359-c8ab-4d6d-b1f0-5c5640b24c09")
    create(:content_item, state: "published", base_path: "/other-page", content_id: "b879bcdb-6160-4bfd-b758-f546bbb408c4")

    post "/lookup-by-base-path", base_paths: ["/my-page", "/other-page", "/does-not-exist"]

    expect(JSON.parse(response.body)).to eql(
      "/my-page" => "b9b2da0a-ec50-4b0e-b29c-b7cbc8195307",
      "/other-page" => "b879bcdb-6160-4bfd-b758-f546bbb408c4",
    )
  end

  it "requires a base_paths param" do
    post "/lookup-by-base-path"

    expect(JSON.parse(response.body)).to eql(
      "error" => { "code" => 422, "message" => "param is missing or the value is empty: base_paths" }
    )
  end
end
