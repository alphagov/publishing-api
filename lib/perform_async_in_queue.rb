module PerformAsyncInQueue
  extend ActiveSupport::Concern

  class_methods do
    def perform_async_in_queue(queue, *args)
      Sidekiq::Client.enqueue_to(queue, self, *args.map(&:deep_stringify_keys))
    end
  end
end
