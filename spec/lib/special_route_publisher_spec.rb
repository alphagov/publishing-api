RSpec.describe SpecialRoutePublisher do
  let(:content_id) { "f3bbdec2-0e62-4520-a7fd-6ffd5d36e03a" }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  describe "#publish_route" do
    it "sets the rendering app" do
      described_class.new.publish_route(content_id:, base_path: "/", title: "Hello", rendering_app: "frontend")

      expect(Edition.first.rendering_app).to eq("frontend")
    end

    context "without a specific locale" do
      it "defaults to english" do
        described_class.new.publish_route(content_id:, base_path: "/", title: "Hello", rendering_app: "frontend")

        expect(Edition.first.locale).to eq("en")
      end
    end

    context "with a specific locale" do
      it "uses the specified locale" do
        described_class.new.publish_route(content_id:, base_path: "/", title: "Hello", rendering_app: "frontend", locale: "cy")

        expect(Edition.first.locale).to eq("cy")
      end
    end

    context "with additional routes" do
      let(:additional_routes) { [base_path: "/homepage.json", type: "exact"] }

      it "calls the Publishing API with all routes specified for the item" do
        described_class.new.publish_route(content_id:, base_path: "/", title: "Hello", rendering_app: "frontend", additional_routes:)

        expect(Edition.first.routes).to eq(
          [
            { path: "/", type: "exact" },
            { path: "/homepage.json", type: "exact" },
          ],
        )
      end
    end

    context "with links" do
      let(:links) do
        {
          organisations: %w[af07d5a5-df63-4ddc-9383-6a666845ebea],
          primary_publishing_organisation: %w[af07d5a5-df63-4ddc-9383-6a666845ebe9],
        }
      end

      it "adds the links" do
        described_class.new.publish_route(content_id:, base_path: "/", title: "Hello", rendering_app: "frontend", links:)

        link_set = Edition.first.document.link_set
        expect(link_set).not_to be_nil
        expect(link_set.links.first.link_type).to eq("organisations")
        expect(link_set.links.first.target_content_id).to eq("af07d5a5-df63-4ddc-9383-6a666845ebea")
        expect(link_set.links.second.link_type).to eq("primary_publishing_organisation")
        expect(link_set.links.second.target_content_id).to eq("af07d5a5-df63-4ddc-9383-6a666845ebe9")
      end
    end
  end
end
