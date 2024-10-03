RSpec.describe HostContentUpdateJob, :perform do
  let(:content_id) { SecureRandom.uuid }
  subject(:worker_perform) do
    described_class.new.perform(
      "content_id" => content_id,
      "locale" => "en",
      "content_store" => "Adapters::ContentStore",
      "orphaned_content_ids" => [],
    )
  end

  let(:dependent_content_id) { SecureRandom.uuid }
  let(:edition_dependent) { double(:edition_dependent, call: [], content_id: dependent_content_id) }
  let(:dependencies) do
    [
      [dependent_content_id, "en"],
    ]
  end

  before do
    allow_any_instance_of(Queries::ContentDependencies).to receive(:call).and_return(dependencies)
  end

  it "queues the Live host content for update" do
    expect(DownstreamLiveJob).to receive(:perform_async_in_queue).with(
      "downstream_low",
      {
        "content_id" => dependent_content_id,
        "dependency_resolution_source_content_id" =>
         content_id,
        "locale" => "en",
        "message_queue_event_type" => "host_content",
        "source_command" => nil,
        "source_fields" => [],
        "update_dependencies" => false,
      },
    )
    worker_perform
  end
end
