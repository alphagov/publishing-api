require "sidekiq-unique-jobs"

class DeletePublishIntentJob
  include DownstreamQueue
  include Sidekiq::Job
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
    PublishingAPI.service(:live_content_store).delete_publish_intent(args["base_path"])
  rescue AbortWorkerError => e
    notify_airbrake(e, args)
  end
end

DeletePublishIntentWorker = DeletePublishIntentJob
