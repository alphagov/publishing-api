module TransactionalCommand
end

RSpec.shared_examples_for TransactionalCommand do
  describe "event logging" do
    it "creates an event for the command" do
      expect {
        described_class.call(payload)
      }.to change(Event, :count).by(1)

      event = Event.last
      expect(event.action).to eq(described_class.name.demodulize)
      expect(event.payload).to eq(payload)
    end

    it "wraps the command in a transaction" do
      allow_any_instance_of(described_class).to receive(:call) do
        create(:live_edition)
        raise "Uh oh, command failed half-way through processing"
      end

      previous_count = Edition.count

      expect {
        described_class.call(payload)
      }.to raise_error(/half-way through/)

      new_count = Edition.count

      expect(new_count).to eq(previous_count),
                           "The transaction should have been rolled back"

      expect(Event.count).to be_zero,
                             "The command should not have logged an event"
    end
  end
end
