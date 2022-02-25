Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqLoggerMiddleware
    # See https://github.com/mhenrixon/sidekiq-unique-jobs/blob/921aaa4efc998b102790d1f4ecce2ebac609e464/README.md#add-the-middleware
    # chain.add SidekiqUniqueJobs::Middleware::Client
  end
end
