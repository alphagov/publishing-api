require "rails_helper"

RSpec.describe DependencyResolutionWorker, :performm do
  let(:content_item) { FactoryGirl.create(:content_item) }

  subject(:worker_perform) do
    described_class.new.perform(content_id: "123",
                    fields: ["base_path"],
                    content_store: "Adapters::DraftContentStore",
                    request_uuid: "123",
                    payload_version: "123",
                   )
  end

  let(:content_item_dependee) { double(:content_item_dependent, call: []) }
  it "finds the content item dependees" do
    expect(Queries::ContentDependencies).to receive(:new).with(
      content_id: "123",
      fields: [:base_path],
      dependent_lookup: an_instance_of(Queries::GetDependees),
    ).and_return(content_item_dependee)
    worker_perform
  end

  it "the dependees get queued in the content store worker" do
    allow_any_instance_of(Queries::ContentDependencies).to receive(:call).and_return([content_item.content_id])
    expect(PresentedContentStoreWorker).to receive(:perform_async).with(
      content_store: Adapters::DraftContentStore,
      payload: a_hash_including(:content_item_id, :payload_version),
      request_uuid: "123",
      enqueue_dependency_check: false,
    )
    worker_perform
  end
end
