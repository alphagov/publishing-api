require 'rails_helper'

RSpec.describe EventLogger do
  let(:command_class) { Commands::PutPublishIntent }
  let(:payload) { { stuff: "1234" } }

  it "records an event, given the name and payload" do
    EventLogger.log_command(command_class, payload)
    expect(Event.count).to eq(1)
    expect(Event.first.action).to eq("PutPublishIntent")
    expect(Event.first.payload).to eq(payload)
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
    content_id = SecureRandom.uuid

    call_counter = 0
    EventLogger.log_command(command_class, payload) do
      if call_counter == 0
        FactoryGirl.create(:live_content_item, content_id: content_id, locale: "en")
        call_counter += 1
        raise CommandRetryableError
      else
        # The original transaction should have been rolled back, so there should be no
        # corresponding LiveContentItem in the database
        expect(LiveContentItem.where(content_id: content_id, locale: "en").count).to eq(0)
        FactoryGirl.create(:live_content_item, content_id: content_id, locale: "en")
      end
    end

    # The second time it was called, it should have succeeded and created an
    # event and a content item
    expect(Event.count).to eq(1)
    expect(LiveContentItem.count).to eq(1)
  end

  it "retries three times in case if a CommandRetryableError is thrown, then raises CommandError" do
    command = double()
    error = CommandRetryableError.new("something went wrong")
    expect(command).to receive(:do_something).exactly(3).times.and_raise(error)
    expect {
      EventLogger.log_command(command_class, payload) do
        command.do_something
      end
    }.to raise_error(CommandError)
    expect(Event.count).to eq(0)
  end

end
