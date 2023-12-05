require "spec_helper"

RSpec.describe "routes", type: :routing do
  it "routes /content-store/live/ to the ContentStore::ContentItems controller" do
    expect(get("/content-store/live/")).to route_to("content_store/content_items#show", content_store: "live")
  end

  it "routes /content-store/draft/ to the ContentStore::ContentItems controller" do
    expect(get("/content-store/draft/")).to route_to("content_store/content_items#show", content_store: "draft")
  end

  it "parses the base_path correctly" do
    expect(get("/content-store/live/guidance/foo")).to route_to("content_store/content_items#show", content_store: "live", base_path: "guidance/foo")
  end
end
