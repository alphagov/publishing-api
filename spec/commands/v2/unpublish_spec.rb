require "rails_helper"

RSpec.describe Commands::V2::Unpublish do
  let(:content_id) { SecureRandom.uuid }
  let(:base_path) { "/vat-rates" }

  describe "call" do
    let(:payload) do
      {
        content_id: content_id,
        type: "gone",
        explanation: "Removed for testing porpoises",
        alternative_path: "/new-path",
      }
    end

    before do
      stub_request(:put, %r{.*content-store.*/content/.*})
    end

    context "when the document is published" do
      let!(:live_content_item) do
        FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: base_path,
        )
      end

      before do
        FactoryGirl.create(:linkable,
          content_item: live_content_item,
          base_path: base_path,
        )
      end

      it "sets the content item's state to `unpublished`" do
        described_class.call(payload)

        state = State.find_by(content_item: live_content_item)
        expect(state.name).to eq("unpublished")
      end

      it "creates an Unpublishing" do
        described_class.call(payload)

        unpublishing = Unpublishing.find_by(content_item: live_content_item)
        expect(unpublishing.type).to eq("gone")
        expect(unpublishing.explanation).to eq("Removed for testing porpoises")
        expect(unpublishing.alternative_path).to eq("/new-path")
      end

      it "deletes the linkable" do
        described_class.call(payload)

        linkable = Linkable.find_by(base_path: base_path)
        expect(linkable).to be_nil
      end

      it "sends an unpublishing to the live content store" do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: a_hash_including(
              document_type: "gone",
            )
        )

        described_class.call(payload)
      end

      it "does not send to any other downstream system" do
        allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        described_class.call(payload)
      end
    end

    context "when only a draft is present" do
      let!(:draft_content_item) do
        FactoryGirl.create(:draft_content_item,
          content_id: content_id,
        )
      end

      it "rejects the request with a 404" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, "Could not find a content item to unpublish") { |error|
          expect(error.code).to eq(404)
        }
      end

      context "and the allow_draft parameter is given" do
        let(:payload_with_allow_draft) do
          payload.merge(
            allow_draft: true,
          )
        end

        it "sets the content item's state to `unpublished`" do
          described_class.call(payload_with_allow_draft)

          state = State.find_by(content_item: draft_content_item)
          expect(state.name).to eq("unpublished")
        end

        it "creates an Unpublishing" do
          described_class.call(payload_with_allow_draft)

          unpublishing = Unpublishing.find_by(content_item: draft_content_item)
          expect(unpublishing.type).to eq("gone")
          expect(unpublishing.explanation).to eq("Removed for testing porpoises")
          expect(unpublishing.alternative_path).to eq("/new-path")
        end

        it "deletes the linkable" do
          described_class.call(payload_with_allow_draft)

          linkable = Linkable.find_by(base_path: base_path)
          expect(linkable).to be_nil
        end

        it "sends an unpublishing to the live content store" do
          expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
            .with(
              base_path: start_with(base_path),
              content_item: a_hash_including(
                document_type: "gone",
              )
          )

          described_class.call(payload_with_allow_draft)
        end

        it "does not send to any other downstream system" do
          allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
          expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

          described_class.call(payload_with_allow_draft)
        end
      end
    end

    context "when the document is redrafted" do
      let!(:live_content_item) do
        FactoryGirl.create(:live_content_item, :with_draft,
          content_id: content_id,
        )
      end

      it "rejects the request with a 422" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, "Cannot unpublish with a draft present") { |error|
          expect(error.code).to eq(422)
        }
      end

      context "with `discard_drafts` set to true" do
        let(:payload) do
          {
            content_id: content_id,
            type: "gone",
            discard_drafts: true,
          }
        end

        before do
          stub_request(:delete, %r{.*content-store.*/content/.*})
        end

        it "discards the draft" do
          described_class.call(payload)

          content_items = ContentItem.where(content_id: content_id)
          expect(content_items.count).to eq(1)

          state = State.find_by(content_item: content_items.first)
          expect(state.name).to eq("unpublished")
        end

        it "unpublishes the content item" do
          described_class.call(payload)
          live_content_item.reload

          unpublishing = Unpublishing.find_by(content_item: live_content_item)
          expect(unpublishing).not_to be_nil
        end
      end
    end

    context "when the document is already unpublished" do
      let!(:unpublished_content_item) do
        FactoryGirl.create(:unpublished_content_item,
          content_id: content_id,
          base_path: base_path,
          explanation: "This explnatin has a typo",
          alternative_path: "/new-path",
        )
      end

      let(:payload) do
        {
          content_id: content_id,
          type: "gone",
          explanation: "This explanation is correct",
        }
      end

      it "updates the Unpublishing" do
        unpublishing = Unpublishing.find_by(content_item: unpublished_content_item)
        expect(unpublishing.explanation).to eq("This explnatin has a typo")

        described_class.call(payload)

        unpublishing.reload

        expect(unpublishing.explanation).to eq("This explanation is correct")
        expect(unpublishing.alternative_path).to be_nil
      end

      it "sends an unpublishing to the live content store" do
        expect(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
          .with(
            base_path: base_path,
            content_item: a_hash_including(
              document_type: "gone",
              details: {
                explanation: "This explanation is correct",
                alternative_path: nil,
              }
            )
        )

        described_class.call(payload)
      end

      it "does not send to any other downstream system" do
        allow(PublishingAPI.service(:live_content_store)).to receive(:put_content_item)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        described_class.call(payload)
      end
    end

    context "with the `downstream` flag set to `false`" do
      before do
        FactoryGirl.create(:live_content_item, :with_draft,
          content_id: content_id,
        )
      end

      it "does not send to any downstream system for a 'gone'" do
        expect(PublishingAPI.service(:live_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        redraft_payload = payload.merge(
          type: "gone",
          discard_drafts: true,
        )
        described_class.call(redraft_payload, downstream: false)
      end

      it "does not send to any downstream system for a 'redirect'" do
        expect(PublishingAPI.service(:live_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        redraft_payload = payload.merge(
          type: "redirect",
          discard_drafts: true,
        )
        described_class.call(redraft_payload, downstream: false)
      end

      it "does not send to any downstream system for a 'withdrawal'" do
        expect(PublishingAPI.service(:live_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:draft_content_store)).not_to receive(:put_content_item)
        expect(PublishingAPI.service(:queue_publisher)).not_to receive(:send_message)

        redraft_payload = payload.merge(
          type: "withdrawal",
          discard_drafts: true,
        )
        described_class.call(redraft_payload, downstream: false)
      end
    end

    context "when trying to unpublish a content item with no location" do
      before do
        content_item = FactoryGirl.create(:live_content_item,
          content_id: content_id,
          base_path: base_path,
        )

        Location.find_by(content_item: content_item).destroy
      end

      it "rejects the request with a 422" do
        expect {
          described_class.call(payload)
        }.to raise_error(CommandError, "Cannot unpublish content with no location") { |error|
          expect(error.code).to eq(422)
        }
      end
    end
  end
end
