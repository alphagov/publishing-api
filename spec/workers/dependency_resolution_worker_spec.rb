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

  let(:content_item_dependent) { double(:content_item_dependent, all: []) }
  it "finds the content item dependents" do
    expect(Queries::ContentItemDependents).to receive(:new).with(
      content_id: "123",
      fields: [:base_path],
    ).and_return(content_item_dependent)
    worker_perform
  end

  it "the dependents get queued in the content store worker" do
    allow_any_instance_of(Queries::ContentItemDependents).to receive(:all).and_return([content_item.content_id])
    expect(PresentedContentStoreWorker).to receive(:perform_async).with(
      content_store: Adapters::DraftContentStore,
      payload: a_hash_including(:content_id, :payload_version),
      request_uuid: "123",
      enqueue_dependency_check: false,
    )
    worker_perform
  end
end
