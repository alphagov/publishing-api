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
end
