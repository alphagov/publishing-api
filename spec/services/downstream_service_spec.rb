require "rails_helper"

RSpec.describe DownstreamService do
  let(:downstream_payload) { double('downstream_payload') }
  let(:state) { "published" }
  let(:content_store_action) { :put }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    stub_request(:delete, %r{.*content-store.*/content/.*})
    allow(downstream_payload).to receive_messages(
      state: state,
      base_path: "/base-path",
      content_store_action: content_store_action,
      content_store_payload: {},
      message_queue_payload: {},
    )
  end

  describe ".update_live_content_store" do
    context "draft item" do
      let(:state) { "draft" }

      it "raises a DownstreamInvalidStateError" do
        expect {
          DownstreamService.update_live_content_store(downstream_payload)
        }.to raise_error(DownstreamInvalidStateError)
      end
    end

    context "put content store action" do
      let(:content_store_action) { :put }

      it "puts content to the live content store" do
        expect(Adapters::ContentStore).to receive(:put_content_item)
        DownstreamService.update_live_content_store(downstream_payload)
      end

      it "doesn't send to draft content store" do
        expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
        DownstreamService.update_live_content_store(downstream_payload)
      end
    end

    context "delete content store action" do
      let(:content_store_action) { :delete }

      it "deletes content from the live content store" do
        expect(Adapters::ContentStore).to receive(:delete_content_item)
        DownstreamService.update_live_content_store(downstream_payload)
      end

      it "doesn't put to live content store" do
        expect(Adapters::ContentStore).to_not receive(:put_content_item)
        DownstreamService.update_live_content_store(downstream_payload)
      end
    end

    context "no_op content store action" do
      let(:content_store_action) { :no_op }

      it "doesn't delete from either content store" do
        expect(Adapters::ContentStore).to_not receive(:put_content_item)
        expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
        DownstreamService.update_live_content_store(downstream_payload)
      end

      it "doesn't put content to either content store" do
        expect(Adapters::ContentStore).to_not receive(:delete_content_item)
        expect(Adapters::DraftContentStore).to_not receive(:delete_content_item)
        DownstreamService.update_live_content_store(downstream_payload)
      end
    end
  end

  describe ".update_draft_content_store" do
    context "draft item" do
      let(:state) { "draft" }

      it "doesn't raise an error" do
        expect {
          DownstreamService.update_draft_content_store(downstream_payload)
        }.to_not raise_error
      end
    end

    context "unpublished item" do
      let(:state) { "unpublished" }

      it "doesn't raise an error" do
        expect {
          DownstreamService.update_draft_content_store(downstream_payload)
        }.to_not raise_error
      end
    end

    context "when we already a draft at this base path" do
      let(:message_matcher) { /Can't send (published|unpublished) item/ }
      before do
        allow(DownstreamService).to receive(:draft_at_base_path?)
          .and_return(true)
      end

      context "when our state is draft" do
        let(:state) { "draft" }

        it "doesn't raise an error" do
          expect {
            DownstreamService.update_draft_content_store(downstream_payload)
          }.to_not raise_error
        end
      end

      context "when our state is published" do
        let(:state) { "published" }

        it "raises an error" do
          expect {
            DownstreamService.update_draft_content_store(downstream_payload)
          }.to raise_error(DownstreamDraftExistsError, message_matcher)
        end
      end

      context "when our state is unpublished" do
        let(:state) { "unpublished" }

        it "raises an error" do
          expect {
            DownstreamService.update_draft_content_store(downstream_payload)
          }.to raise_error(DownstreamDraftExistsError, message_matcher)
        end
      end
    end

    context "put content store action" do
      let(:content_store_action) { :put }

      it "puts content to the draft content store" do
        expect(Adapters::DraftContentStore).to receive(:put_content_item)
        DownstreamService.update_draft_content_store(downstream_payload)
      end

      it "doesn't send to live content store" do
        expect(Adapters::ContentStore).to_not receive(:put_content_item)
        DownstreamService.update_draft_content_store(downstream_payload)
      end
    end

    context "delete content store action" do
      let(:content_store_action) { :delete }

      it "deletes content from the draft content store" do
        expect(Adapters::DraftContentStore).to receive(:delete_content_item)
        DownstreamService.update_draft_content_store(downstream_payload)
      end

      it "doesn't put to draft content store" do
        expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
        DownstreamService.update_draft_content_store(downstream_payload)
      end
    end

    context "no_op content store action" do
      let(:content_store_action) { :no_op }

      it "doesn't delete from either content store" do
        expect(Adapters::ContentStore).to_not receive(:put_content_item)
        expect(Adapters::DraftContentStore).to_not receive(:put_content_item)
        DownstreamService.update_draft_content_store(downstream_payload)
      end

      it "doesn't put content to either content store" do
        expect(Adapters::ContentStore).to_not receive(:delete_content_item)
        expect(Adapters::DraftContentStore).to_not receive(:delete_content_item)
        DownstreamService.update_draft_content_store(downstream_payload)
      end
    end
  end

  describe ".broadcast_to_message_queue" do
    let(:update_type) { "major" }
    let(:state) { "published" }

    {
      "draft" => true,
      "published" => false,
      "unpublished" => false,
      "superseded" => true,
    }.each do |state, should_error|
      context "#{state} item" do
        let(:state) { state }

        if should_error
          it "should raise a DownstreamInvalidStateError" do
            expect {
              DownstreamService.broadcast_to_message_queue(downstream_payload, update_type)
            }.to raise_error(DownstreamInvalidStateError)
          end
        else
          it "should not raise an error" do
            expect {
              DownstreamService.broadcast_to_message_queue(downstream_payload, update_type)
            }.to_not raise_error
          end
        end
      end
    end

    it "sends a message to the message queue" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
      DownstreamService.broadcast_to_message_queue(downstream_payload, update_type)
    end
  end

  describe ".discard_from_draft_content_store" do
    context "nil base path" do
      it "doesn't delete from draft content store" do
        expect(Adapters::DraftContentStore).to_not receive(:delete_content_item)
        DownstreamService.discard_from_draft_content_store(nil)
      end
    end

    context "base path conflict" do
      before do
        allow(DownstreamService).to receive(:discard_draft_base_path_conflict?)
          .and_return(true)
      end

      it "raises a DiscardDraftBasePathConflictError" do
        expect {
          DownstreamService.discard_from_draft_content_store("/test")
        }.to raise_error(DiscardDraftBasePathConflictError)
      end
    end

    context "doesn't have a base path conflict" do
      it "deletes from draft content store" do
        expect(Adapters::DraftContentStore).to receive(:delete_content_item)
        DownstreamService.discard_from_draft_content_store("/test")
      end
    end
  end

  describe ".discard_draft_base_path_conflict?" do
    context "nil base path" do
      it "returns false" do
        response = DownstreamService.discard_draft_base_path_conflict?(nil)
        expect(response).to be false
      end
    end

    context "no conflict" do
      it "returns false" do
        response = DownstreamService.discard_draft_base_path_conflict?("/no-conflict")
        expect(response).to be false
      end
    end

    context "conflict" do
      before do
        create(:unpublished_edition, base_path: "/test")
      end

      it "returns true" do
        response = DownstreamService.discard_draft_base_path_conflict?("/test")
        expect(response).to be true
      end
    end
  end
end
