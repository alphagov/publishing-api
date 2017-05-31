require "rails_helper"

RSpec.shared_examples "creates an action" do
  it "creates an action" do
    expect(Action.count).to be 0
    described_class.call(action_payload)
    expect(Action.count).to be 1
    expect(Action.first.attributes).to match a_hash_including(
      "content_id" => content_id,
      "locale" => locale,
      "action" => action,
    )
  end
end
