require "rails_helper"

RSpec.describe DependencyResolutionWorker, :perform do
  let(:live_content_item) { FactoryGirl.create(:live_content_item) }

  subject(:worker_perform) do
    described_class.new.perform(content_id: "123",
                    fields: ["base_path"],
                    content_store: "Adapters::ContentStore",
                    payload_version: "123",
                   )
  end

  let(:content_item_dependee) { double(:content_item_dependent, call: []) }

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    allow_any_instance_of(Queries::ContentDependencies).to receive(:call).and_return([live_content_item.content_id])
  end

  it "finds the content item dependees" do
    expect(Queries::ContentDependencies).to receive(:new).with(
      content_id: "123",
      fields: [:base_path],
      dependent_lookup: an_instance_of(Queries::GetDependees),
    ).and_return(content_item_dependee)
    worker_perform
  end

  it "the dependees get queued in the content store worker" do
    expect(DownstreamPublishWorker).to receive(:perform_async_in_queue).with(
      "downstream_low",
      a_hash_including(
        :content_item_id,
        :payload_version,
        message_queue_update_type: "links",
        update_dependencies: false
      ),
    )
    worker_perform
  end

  context "with a draft version available" do
    let!(:draft_content_item) {
      FactoryGirl.create(:draft_content_item,
        content_id: live_content_item.content_id
      )
    }

    it "doesn't send draft content to the live content store" do
      expect(DownstreamPublishWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(
          content_item_id: live_content_item.id,
        )
      )

      described_class.new.perform(
        content_id: "123",
        fields: ["base_path"],
        content_store: "Adapters::ContentStore",
        payload_version: "123",
      )
    end

    it "does send draft content to the draft content store" do
      expect(PresentedContentStoreWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(
          payload: a_hash_including(
            content_item_id: draft_content_item.id,
          )
        )
      )

      described_class.new.perform(
        content_id: "123",
        fields: ["base_path"],
        content_store: "Adapters::DraftContentStore",
        payload_version: "123",
      )
    end
  end
end
