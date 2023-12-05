require "sidekiq-unique-jobs"

class PutPublishIntentWorker
  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE,
                  lock: :until_executing,
                  lock_args_method: :uniq_args,
                  on_conflict: :log

  def self.uniq_args(args)
    [
      args.first["base_path"],
      name,
    ]
  end

  def perform(args = {})
    Adapters::ContentStore.put_publish_intent(args["base_path"], JSON.parse(args["payload"]))
  rescue AbortWorkerError => e
    notify_airbrake(e, args)
  end
end
