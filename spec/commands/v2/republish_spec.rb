RSpec.describe Commands::V2::Republish do
  describe "call" do
    before do
      stub_request(:put, %r{.*content-store.*/content/.*})

      allow(DependencyResolutionWorker).to receive(:perform_async)
    end

    let!(:published_edition) { create(:live_edition) }

    let(:payload) do
      {
        content_id: published_edition.content_id,
        previous_version: 1,
      }
    end

    it "overwrites the publishing_request_id" do
      request_id = SecureRandom.uuid
      GdsApi::GovukHeaders.set_header(:govuk_request_id, request_id)
      expect { described_class.call(payload) }
        .to change { published_edition.reload.publishing_request_id }
        .to(request_id)
    end

    it "creates an action" do
      expect { described_class.call(payload) }
        .to change { Action.count }.by(1)

      action = Action.last
      expect(action.action).to eq("Republish")
      expect(action.content_id).to eq(published_edition.content_id)
    end

    it "calls the DownstreamLiveWorker" do
      expect(DownstreamLiveWorker)
        .to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          content_id: published_edition.content_id,
          locale: published_edition.locale,
          message_queue_event_type: "republish",
          update_dependencies: true,
          source_command: "republish",
        )

      described_class.call(payload)
    end

    it "calls the DownstreamDraftWorker" do
      expect(DownstreamDraftWorker)
        .to receive(:perform_async_in_queue)
        .with(
          "downstream_high",
          content_id: published_edition.content_id,
          locale: published_edition.locale,
          update_dependencies: true,
          source_command: "republish",
        )

      described_class.call(payload)
    end

    context "when the edition is unpublished" do
      let(:edition) { create(:unpublished_edition) }

      it "sets the edition state to published" do
        expect { described_class.call({ content_id: edition.content_id }) }
          .to change { edition.reload.state }
          .from("unpublished")
          .to("published")
      end

      it "deletes the unpublishing" do
        expect { described_class.call({ content_id: edition.content_id }) }
          .to change { edition.reload.unpublishing }
          .to(nil)
      end
    end

    context "when previous_version is old" do
      let(:edition) do
        create(:live_edition, document: build(:document, stale_lock_version: 2))
      end

      it "sets the edition state to published" do
        payload = { content_id: edition.content_id, previous_version: 1 }
        expect { described_class.call(payload) }
          .to raise_error(CommandError, /Conflict/)
      end
    end

    context "when the edition isn't live" do
      let(:edition) { create(:draft_edition) }

      it "raises an error" do
        expect { described_class.call({ content_id: edition.content_id }) }
          .to raise_error(CommandError, /does not exist/)
      end
    end

    context "when the document also has a draft edition" do
      let(:document) { create(:document) }

      before do
        create(:live_edition, document:)
        create(:draft_edition, document:, user_facing_version: 2)
      end

      it "doesn't call the DownstreamDraftWorker" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        described_class.call({ content_id: document.content_id })
      end
    end

    context "when the downstream parameter is false" do
      it "doesn't call the DownstreamDraftWorker" do
        expect(DownstreamDraftWorker).not_to receive(:perform_async_in_queue)
        described_class.call(payload, downstream: false)
      end

      it "doesn't call the DownstreamLiveWorker" do
        expect(DownstreamLiveWorker).not_to receive(:perform_async_in_queue)
        described_class.call(payload, downstream: false)
      end
    end

    it_behaves_like TransactionalCommand
  end
end
