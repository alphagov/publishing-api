require "rails_helper"

RSpec.describe PerformAsyncInQueue do
  describe ".perform_async_in_queue" do
    let!(:worker_class) { ExampleWorker = Class.new { include PerformAsyncInQueue } }

    it "calls client_push with the correct queue name" do
      expect(Sidekiq::Client)
        .to receive(:enqueue_to)
        .with("foo", ExampleWorker, "bar")

      ExampleWorker.perform_async_in_queue("foo", "bar")
    end
  end
end
