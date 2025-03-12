RSpec.describe RemoveOldEventsJob, :perform do
  before do
    @event_1 = create(:event, created_at: 31.days.ago)
    @event_2 = create(:event, created_at: 29.days.ago)
  end

  it "deletes only records older than 30 days" do
    described_class.new.perform

    expect { @event_1.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(@event_2.reload).to be_present
  end
end
