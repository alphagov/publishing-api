class RequeueContentByScope
  DEFAULT_ACTION = "bulk.reindex".freeze
  DEFAULT_BATCH_SIZE = 1_000

  IMPORT_QUEUE_JOBS_LIMIT = 5_000
  IMPORT_QUEUE_JOBS_LIMIT_WAIT_DURATION = 5.seconds

  def initialize(scope, action: DEFAULT_ACTION, batch_size: DEFAULT_BATCH_SIZE)
    raise ArgumentError, "Action must be provided" if action.blank?
    # Major updates would spam subscribers with email alerts
    raise ArgumentError, "Requeuing major updates is disruptive and not allowed" if /major/.match?(action)

    @scope = scope.select(:id)
    @action = action

    @batch_size = batch_size
  end

  def call
    scope.find_each(batch_size:) do |edition|
      while queue.size > IMPORT_QUEUE_JOBS_LIMIT
        warn "Pending jobs have exceeded limit of #{IMPORT_QUEUE_JOBS_LIMIT}, waiting for some " \
          "jobs to clear before continuing."

        sleep IMPORT_QUEUE_JOBS_LIMIT_WAIT_DURATION
      end

      RequeueContent.perform_async(edition.id, version, action)
    end
  end

private

  attr_reader :scope, :action, :batch_size

  def version
    @version ||= Event.maximum(:id)
  end

  def queue
    @queue ||= Sidekiq::Queue.new("import")
  end
end
