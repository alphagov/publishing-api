require "rails_helper"

RSpec.describe "Reallocating base paths of content items" do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }

  before do
    stub_request(:put, %r{.*draft-content-store.*/content/.*})
  end

  let(:regular_payload) do
    FactoryGirl.build(:draft_edition,
      document: FactoryGirl.create(:document, content_id: content_id),
    ).as_json.deep_symbolize_keys.merge(base_path: base_path)
  end

  describe "/v2/content" do
    context "when a base path is occupied by a 'regular' content item" do
      before do
        FactoryGirl.create(:draft_edition,
          base_path: base_path,
        )
      end

      it "cannot be replaced by another 'regular' content item" do
        put "/v2/content/#{content_id}", params: regular_payload.to_json
        expect(response.status).to eq(422)
      end
    end
  end

  describe "publishing a draft which has a different content_id to the published content item on the same base_path" do
    let(:draft_document) { FactoryGirl.create(:document) }
    let(:live_document) { FactoryGirl.create(:document) }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when both content items are 'regular' content items" do
      before do
        draft = FactoryGirl.create(:draft_edition,
          document: draft_document,
          base_path: base_path
        )

        live = FactoryGirl.create(:live_edition,
          document: live_document,
          base_path: base_path
        )

        FactoryGirl.create(:lock_version, target: live, number: 5)
        FactoryGirl.create(:lock_version, target: draft, number: 3)
      end

      it "raises an error" do
        post "/v2/content/#{draft_document.content_id}/publish",
          params: { update_type: "major", content_id: draft_document.content_id }.to_json

        expect(response.status).to eq(422)
      end
    end
  end
end
