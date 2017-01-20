require "rails_helper"

RSpec.describe DependencyResolutionWorker, :perform do
  let(:content_id) { SecureRandom.uuid }
  let(:locale) { "en" }
  let(:document) { FactoryGirl.create(:document, content_id: content_id, locale: locale) }
  let(:live_edition) { FactoryGirl.create(:live_edition, document: document) }

  subject(:worker_perform) do
    described_class.new.perform(
      content_id: content_id,
      locale: locale,
      content_store: "Adapters::ContentStore",
      payload_version: "123",
    )
  end

  let(:edition_dependee) { double(:edition_dependent, call: []) }
  let(:dependencies) do
    [
      [content_id, "en"],
    ]
  end

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    allow_any_instance_of(Queries::ContentDependencies).to receive(:call).and_return(dependencies)
  end

  it "finds the edition dependees" do
    expect(Queries::ContentDependencies).to receive(:new).with(
      content_id: content_id,
      locale: locale,
      content_stores: %w[live],
    ).and_return(edition_dependee)
    worker_perform
  end

  it "the dependees get queued in the content store worker" do
    expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
      "downstream_low",
      a_hash_including(
        :content_id,
        :locale,
        :payload_version,
        message_queue_update_type: "links",
        update_dependencies: false,
      ),
    )
    worker_perform
  end

  context "with a draft version available" do
    let!(:draft_edition) do
      FactoryGirl.create(:draft_edition,
        document: document,
        user_facing_version: 2,
      )
    end

    it "doesn't send draft content to the live content store" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(
          content_id: content_id,
          locale: "en",
        )
      )

      described_class.new.perform(
        content_id: "123",
        content_store: "Adapters::ContentStore",
        payload_version: "123",
      )
    end

    it "does send draft content to the draft content store" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(
          content_id: content_id,
          locale: "en",
        )
      )

      described_class.new.perform(
        content_id: "123",
        content_store: "Adapters::DraftContentStore",
        payload_version: "123",
      )
    end
  end

  context "when there are translations of an edition" do
    context "and locale is specified" do
      let(:dependencies) do
        [
          [content_id, "fr"],
          [content_id, "es"],
        ]
      end

      after do
        described_class.new.perform(
          content_id: content_id,
          locale: "en",
          content_store: "Adapters::ContentStore",
          payload_version: "123",
        )
      end

      it "downstreams all but the locale specified" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "fr")
        )
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "es")
        )
      end
    end

    context "but locale is not specified" do
      let(:dependencies) do
        [
          [content_id, "en"],
          [content_id, "fr"],
          [content_id, "es"],
        ]
      end

      after do
        described_class.new.perform(
          content_id: content_id,
          content_store: "Adapters::ContentStore",
          payload_version: "123",
        )
      end

      it "downstreams all but the locale specified" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "en")
        )
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "fr")
        )
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "es")
        )
      end
    end
  end
end
