require 'rails_helper'

RSpec.describe EventLogger do
  let(:user_uid) {"f4897b18-f2be-460d-83ef-bda2b26fa9a4"}
  let(:action) {"create draft"}
  let(:payload) {
    {
      stuff: "1234"
    }
  }

  it "records an event, given the name, payload and user id" do
    EventLogger.new.log(action, user_uid, payload)
    expect(Event.count).to eq(1)
    expect(Event.first.action).to eq(action)
    expect(Event.first.user_uid).to eq(user_uid)
    expect(Event.first.payload).to eq(payload)
  end

  it "executes a provided block passing the event" do
    ran_block = false
    event = nil
    EventLogger.new.log(action, user_uid, payload) do |e|
      ran_block = true
      event = e
    end
    expect(ran_block).to eq(true)
    expect(event).to be_a(Event)
  end

  it "returns the return value of the block" do
    value = EventLogger.new.log(action, user_uid, payload) do
      "yes"
    end
    expect(value).to eq("yes")
  end

  it "does not record an event if the block raises an uncaught exception" do
    expect {
      EventLogger.new.log(action, user_uid, payload) do
        raise "unchecked error"
      end
    }.to raise_error("unchecked error")
    expect(Event.count).to eq(0)
  end

  it "rolls back the transaction and retries if a Command::Retry is thrown" do
    call_counter = 0
    EventLogger.new.log(action, user_uid, payload) do
      if call_counter == 0
        LiveContentItem.create(content_id: "1234", locale: "en", version: 1)
        call_counter += 1
        raise Command::Retry
      else
        # The original transaction should have been rolled back, so there should be no
        # corresponding LiveContentItem in the database
        expect(LiveContentItem.where(content_id: "1234", locale: "en").count).to eq(0)
        LiveContentItem.create(content_id: "1234", locale: "en", version: 1)
      end
    end

    # The second time it was called, it should have succeeded and created an
    # event and a content item
    expect(Event.count).to eq(1)
    expect(LiveContentItem.count).to eq(1)
  end

  it "retries three times in case if a Command::Retry is thrown, then raises Command::Error" do
    command = double()
    error = Command::Retry.new("something went wrong")
    expect(command).to receive(:do_something).exactly(3).times.and_raise(error)
    expect {
      EventLogger.new.log(action, user_uid, payload) do
        command.do_something
      end
    }.to raise_error(Command::Error)
    expect(Event.count).to eq(0)
  end

end
