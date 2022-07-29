RSpec.describe EventLogger do
  let(:command_class) { Commands::PutPublishIntent }
  let(:payload) { { stuff: "1234" } }

  before do
    allow(GdsApi::GovukHeaders).to receive(:headers)
      .and_return(govuk_request_id: "09876-54321")
  end

  it "records an event, given the name and payload" do
    EventLogger.log_command(command_class, payload)
    expect(Event.count).to eq(1)
    expect(Event.first.action).to eq("PutPublishIntent")
    expect(Event.first.payload).to eq(payload)
    expect(Event.first.request_id).to eq("09876-54321")
  end

  it "returns the return value of the block" do
    value = EventLogger.log_command(command_class, payload) do
      "yes"
    end
    expect(value).to eq("yes")
  end

  it "does not record an event if the block raises an uncaught exception" do
    expect {
      EventLogger.log_command(command_class, payload) do
        raise "unchecked error"
      end
    }.to raise_error("unchecked error")
    expect(Event.count).to eq(0)
  end

  it "rolls back the transaction and retries if a CommandRetryableError is thrown" do
    document = create(:document)

    call_counter = 0
    EventLogger.log_command(command_class, payload) do
      if call_counter == 0
        create(:live_edition, document:)
        call_counter += 1
        raise CommandRetryableError
      else
        # The original transaction should have been rolled back, so there should be no
        # corresponding ContentItem in the database
        expect(Edition.where(document:).count).to eq(0)
        create(:live_edition, document:)
      end
    end

    # The second time it was called, it should have succeeded and created an
    # event and an edition
    expect(Event.count).to eq(1)
    expect(Edition.count).to eq(1)
  end

  it "retries five times in case if a CommandRetryableError is thrown, then raises CommandError" do
    command = double
    error = CommandRetryableError.new("something went wrong")
    expect(command).to receive(:do_something).exactly(5).times.and_raise(error)
    expect {
      EventLogger.log_command(command_class, payload) do
        command.do_something
      end
    }.to raise_error(CommandError)
    expect(Event.count).to eq(0)
  end

  it "adds the content ID if present" do
    content_id = SecureRandom.uuid

    EventLogger.log_command(Commands::V2::Publish, content_id:)
    expect(Event.count).to eq(1)
    expect(Event.last.content_id).to eq(content_id)

    EventLogger.log_command(Commands::V2::Publish, {})
    expect(Event.count).to eq(2)
    expect(Event.last.content_id).to be_nil
  end
end
