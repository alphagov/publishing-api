require "rails_helper"

RSpec.describe "Reallocating base paths of content items" do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }

  before do
    stub_request(:put, %r{.*draft-content-store.*/content/.*})
  end

  let(:regular_payload) do
    FactoryGirl.build(:draft_content_item,
      content_id: content_id,
    ).as_json.deep_symbolize_keys.merge(base_path: base_path)
  end

  describe "/v2/content" do
    let(:request_body) { regular_payload.to_json }
    let(:request_path) { "/v2/content/#{content_id}" }
    let(:request_method) { :put }

    context "when a base path is occupied by a 'regular' content item" do
      before do
        FactoryGirl.create(
          :draft_content_item,
          base_path: base_path,
        )
      end

      it "cannot be replaced by another 'regular' content item" do
        do_request
        expect(response.status).to eq(422)
      end
    end
  end

  describe "publishing a draft which has a different content_id to the published content item on the same base_path" do
    let(:draft_content_id) { SecureRandom.uuid }
    let(:live_content_id) { SecureRandom.uuid }

    let(:request_body) { { update_type: "major", content_id: draft_content_id }.to_json }
    let(:request_path) { "/v2/content/#{draft_content_id}/publish" }
    let(:request_method) { :post }

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when both content items are 'regular' content items" do
      before do
        draft = FactoryGirl.create(
          :draft_content_item,
          content_id: draft_content_id,
          base_path: base_path
        )

        live = FactoryGirl.create(
          :live_content_item,
          content_id: live_content_id,
          base_path: base_path
        )

        FactoryGirl.create(:lock_version, target: live, number: 5)
        FactoryGirl.create(:lock_version, target: draft, number: 3)
      end

      it "raises an error" do
        do_request
        expect(response.status).to eq(422)
      end
    end
  end

  describe "/content" do
    let(:request_body) { regular_payload.to_json }
    let(:request_path) { "/content#{base_path}" }
    let(:request_method) { :put }

    context "when a base path is occupied by a not-yet-published regular content item" do
      before do
        FactoryGirl.create(
          :draft_content_item,
          base_path: base_path
        )
      end

      it "cannot be replaced by another regular content item" do
        do_request
        expect(response.status).to eq(422)
      end
    end

    context "when a base path is occupied by a published regular content item" do
      before do
        FactoryGirl.create(
          :live_content_item,
          :with_draft,
          base_path: base_path
        )
      end

      it "cannot be replaced by another regular content item" do
        do_request
        expect(response.status).to eq(422)
      end
    end
  end
end
