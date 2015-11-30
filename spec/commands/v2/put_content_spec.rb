require "rails_helper"

RSpec.describe Commands::V2::PutContent do
  describe "call" do
    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    let(:content_id) { SecureRandom.uuid }
    let(:base_path) { "/vat-rates" }

    let(:payload) {
      FactoryGirl.build(:draft_content_item)
        .as_json
        .deep_symbolize_keys
        .merge(
          content_id: content_id,
          title: "The title",
          base_path: base_path
        )
    }

    describe "validation" do
      before do
        create(:path_reservation, publishing_app: payload[:publishing_app], base_path: base_path)
        create(:live_content_item, content_id: content_id, base_path: base_path)
      end

      context "given a base_path change on a published item" do
        let(:updated_payload) { payload.merge(base_path: "/vatrates") }

        it "raises an error" do
          expect { described_class.call(updated_payload) }.to raise_error(
            CommandError, /Base path cannot be changed for published items/)
        end
      end

      context "given a publishing_app change on a published item" do
        let(:updated_payload) { payload.merge(publishing_app: "new-publishing-app") }
        it "raises an error" do
          expect { described_class.call(updated_payload) }.to raise_error(
            CommandError, "Base path is already registered by mainstream_publisher")
        end
      end

      context "given a field change on a published item" do
        let(:updated_payload) { payload.merge(title: "A better title") }

        it "passes validation" do
          expect(Commands::Success).to receive(:new)

          described_class.call(updated_payload)
        end
      end

      context "given a payload which invalidates an existing content item" do
        let!(:draft) do
          FactoryGirl.create(:draft_content_item, content_id: content_id, base_path: base_path)
        end

        let!(:version) { FactoryGirl.create(:version, target: draft, number: 2) }

        # This payload will invalidate the existing item when the
        # attributes are merged as redirects do not have routes.
        let(:updated_payload) do
          payload.except(:routes)
            .merge(format: "redirect",
                   redirects: [{
                     type: "exact",
                     path: "/vat-rates",
                     destination: "/vat-rates/overview"
                    }])
        end

        it "assigns attribute defaults before incrementing the version" do
          described_class.call(updated_payload)

          expect(version.reload.number).to eq(3)
          expect(draft.reload.format).to eq("redirect")
        end
      end
    end

    it "presents the updated content in the response body" do
      result = described_class.call(payload)
      expect(result.data[:version]).to eq(1)
    end
  end
end
