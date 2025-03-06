RSpec.describe HostContentUpdateJob, :perform do
  let(:content_id) { SecureRandom.uuid }
  let(:document_type) { "content_block_email_address" }
  let(:edition) { build(:live_edition, document_type:) }
  let(:document) { build(:document, live: edition, content_id:) }

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
    allow(Document).to receive(:find_by).with(content_id:).and_return(document)
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

  it "creates an event" do
    create(:event, content_id:, action: "PatchLinkSet", created_at: 5.days.ago)
    create(:event, content_id:, action: "PutContent", created_at: 4.days.ago)
    create(:event, content_id:, action: "Publish", created_at: 3.days.ago)
    create(:event, content_id:, action: "HostContentUpdateJob", created_at: 2.days.ago)
    create(:event, content_id:, action: "PutContent", created_at: 1.day.ago)
    latest_publish_event = create(:event, content_id:, action: "Publish", user_uid: SecureRandom.uuid, created_at: Time.zone.now)

    expect { worker_perform }.to change(Event, :count).by(1)

    event = Event.last

    expect(event.action).to eq("HostContentUpdateJob")
    expect(event.content_id).to eq(dependent_content_id)
    expect(event.payload[:source_block][:title]).to eq(edition.title)
    expect(event.payload[:source_block][:content_id]).to eq(content_id)
    expect(event.payload[:source_block][:document_type]).to eq(document_type)
    expect(event.payload[:source_block][:updated_by_user_uid]).to eq(latest_publish_event.user_uid)
    expect(event.payload[:message]).to eq("Host content updated by content block update")
  end

  describe "when the locale is a non-English locale" do
    subject(:worker_perform) do
      described_class.new.perform(
        "content_id" => content_id,
        "locale" => "cy",
        "content_store" => "Adapters::ContentStore",
        "orphaned_content_ids" => [],
      )
    end

    let(:edition_dependee) { double(:edition_dependent, call: []) }

    it "does not specify a locale" do
      expect(Queries::ContentDependencies).to receive(:new).with(
        content_id:,
        locale: nil,
        content_stores: %w[live],
      ).and_return(edition_dependee)

      worker_perform
    end
  end
end
