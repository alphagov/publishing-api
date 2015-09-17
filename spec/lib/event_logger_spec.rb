require 'rails_helper'

RSpec.describe EventLogger do
  let(:user_uid) {"f4897b18-f2be-460d-83ef-bda2b26fa9a4"}
  let(:action) {"create draft"}
  let(:payload) {
    {
      "stuff" => "1234"
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

end
