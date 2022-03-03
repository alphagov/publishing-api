require "rails_helper"

RSpec.describe DownstreamLiveWorker do
  let(:edition) do
    create(:live_edition, base_path: "/foo")
  end

  let(:content_id) { edition.document.content_id }

  let(:base_arguments) do
    {
      "content_id" => content_id,
      "locale" => "en",
      "message_queue_event_type" => "major",
      "update_dependencies" => true,
    }
  end

  let(:arguments) { base_arguments }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
  end

  specify { expect(described_class).to have_valid_sidekiq_options }

  describe "arguments" do
    it "requires content_item_id or content_id" do
      expect {
        subject.perform(arguments.except("content_id"))
      }.to raise_error(KeyError)
      expect {
        subject.perform(arguments.merge("content_item_id" => edition.id))
      }.not_to raise_error
    end

    it "doesn't require message_queue_event_type" do
      expect {
        subject.perform(arguments.except("message_queue_event_type"))
      }.not_to raise_error
    end

    it "doesn't require update_dependencies" do
      expect {
        subject.perform(arguments.except("update_dependencies"))
      }.not_to raise_error
    end
  end

  describe "send to live content store" do
    context "published edition" do
      it "sends content to live content store" do
        expect(Adapters::ContentStore).to receive(:put_content_item)
        subject.perform(arguments)
      end
    end

    context "unpublished edition" do
      let(:unpublished_edition) { create(:unpublished_edition) }
      let(:unpublished_arguments) { arguments.merge(content_id: unpublished_edition.document.content_id) }

      it "sends content to live content store" do
        expect(Adapters::ContentStore).to receive(:put_content_item)
        subject.perform(unpublished_arguments)
      end
    end

    context "superseded edition" do
      let(:superseded_edition) { create(:superseded_edition) }
      let(:superseded_arguments) { arguments.merge(content_id: superseded_edition.document.content_id) }

      it "doesn't send to live content store" do
        expect(Adapters::ContentStore).to_not receive(:put_content_item)
        subject.perform(superseded_arguments)
      end

      it "absorbs an error" do
        expect(GovukError).to receive(:notify)
          .with(an_instance_of(AbortWorkerError), a_hash_including(:extra))
        subject.perform(superseded_arguments)
      end
    end

    it "wont send to content store without a base_path" do
      pathless = create(
        :live_edition,
        base_path: nil,
        document_type: "contact",
        schema_name: "contact",
      )
      expect(Adapters::ContentStore).to_not receive(:put_content_item)
      subject.perform(arguments.merge("content_id" => pathless.document.content_id))
    end
  end

  describe "updates expanded links" do
    it "creates a ExpandedLinks entry" do
      expect { subject.perform(arguments) }
        .to(change { ExpandedLinks.exists?(content_id: content_id, with_drafts: false) })
    end

    context "when there aren't any links" do
      it "has only available_translations in the cache" do
        subject.perform(arguments)
        links = ExpandedLinks.find_by(content_id: content_id).expanded_links
        expect(links).to match a_hash_including("available_translations")
      end
    end
  end

  describe "broadcast to message queue" do
    it "sends a message" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)

      subject.perform(arguments)
    end

    it "uses the `message_queue_event_type`" do
      expect(PublishingAPI.service(:queue_publisher)).to receive(:send_message)
        .with(hash_including(update_type: "minor"), event_type: "minor")

      subject.perform(arguments.merge("message_queue_event_type" => "minor"))
    end
  end

  describe "update dependencies" do
    context "can update dependencies" do
      let(:arguments) do
        base_arguments.merge("update_dependencies" => true, "source_command" => "command")
      end

      it "enqueues dependencies" do
        expect(DependencyResolutionWorker).to receive(:perform_async)
        subject.perform(arguments)
      end

      it "sends the source command to the worker" do
        expect(DependencyResolutionWorker).to receive(:perform_async)
          .with(a_hash_including(source_command: "command"))
        subject.perform(arguments)
      end

      it "sends the document type to the worker" do
        expect(DependencyResolutionWorker).to receive(:perform_async)
          .with(a_hash_including(source_document_type: "services_and_information"))
        subject.perform(arguments)
      end

      it "sends the dependency resolution fields to the worker" do
        expect(DependencyResolutionWorker).to receive(:perform_async)
          .with(a_hash_including(source_fields: %i[field]))
        subject.perform(arguments.merge("source_fields" => %i[field]))
      end
    end

    context "can not update dependencies" do
      it "doesn't enqueue dependencies" do
        expect(DependencyResolutionWorker).to_not receive(:perform_async)
        subject.perform(arguments.merge("update_dependencies" => false))
      end
    end
  end

  describe "draft-to-live protection" do
    it "rejects draft editions" do
      draft = create(:draft_edition)

      expect(GovukError).to receive(:notify)
        .with(an_instance_of(AbortWorkerError), a_hash_including(:extra))
      subject.perform(arguments.merge("content_id" => draft.document.content_id))
    end

    it "allows live editions" do
      live = create(:live_edition)

      expect(GovukError).to_not receive(:notify)
      subject.perform(arguments.merge("content_id" => live.document.content_id))
    end
  end

  describe "no edition" do
    it "swallows the error" do
      expect(GovukError).to receive(:notify)
        .with(an_instance_of(AbortWorkerError), a_hash_including(:extra))
      subject.perform(arguments.merge("content_id" => SecureRandom.uuid))
    end
  end
end
