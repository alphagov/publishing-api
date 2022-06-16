RSpec.describe DistributedLock do
  describe ".lock" do
    context "when it runs successfully" do
      it "returns the block value" do
        result = described_class.lock("lock_name") { :complete }
        expect(result).to eq(:complete)
      end
    end

    context "when it fails to acquire a lock within the timeout" do
      before do
        allow(ActiveRecord::Base).to receive(:with_advisory_lock).and_return(false)
      end

      it "raises DistributedLock::FailedToAcquireLock" do
        run = -> { described_class.lock("lock_name") { :complete } }

        expect { run.call }.to raise_error(DistributedLock::FailedToAcquireLock)
      end
    end
  end
end
