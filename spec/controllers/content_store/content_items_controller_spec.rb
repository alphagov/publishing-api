require "spec_helper"

RSpec.describe ContentStore::ContentItemsController, type: :controller do
  let!(:document_en) do
    create(:document, locale: "en")
  end
  let!(:live_edition) do
    create(
      :live_edition,
      document: document_en,
      base_path: "/content.en",
      document_type: "guide",
      schema_name: "topic",
      user_facing_version: 1,
    )
  end
  let!(:draft_edition) do
    create(
      :draft_edition,
      document: document_en,
      base_path: "/content.en",
      document_type: "topic",
      schema_name: "topic",
      user_facing_version: 2,
    )
  end

  describe "#show" do
    context "when there is an edition at the given base_path with the given content_store" do
      let(:params) { { base_path: "content.en", content_store: "live" } }

      it "responds with the json content store representation of the edition" do
        get(:show, params:)
        expect(parsed_response).to include(
          {
            "title" => live_edition.title,
            "description" => live_edition.description,
          },
        )
      end

      it "has version set to the user-facing version number" do
        get(:show, params:)
        expect(parsed_response).to include(
          {
            "payload_version" => live_edition.user_facing_version,
          },
        )
      end
    end

    context "when there is not an edition at the given base_path with the given content_store" do
      let(:params) { { base_path: "no-content-here", content_store: "live" } }
      it "responds with a 404" do
        get(:show, params:)
        expect(response.status).to eq(404)
      end
    end
  end
end
