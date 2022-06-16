RSpec.describe PerformAsyncInQueue do
  describe ".perform_async_in_queue" do
    before do
      stub_const("ExampleWorker", Class.new { include PerformAsyncInQueue })
    end

    it "calls client_push with the correct queue name" do
      expect(Sidekiq::Client)
        .to receive(:enqueue_to)
        .with("foo", ExampleWorker, "bar")

      ExampleWorker.perform_async_in_queue("foo", "bar")
    end
  end
end
