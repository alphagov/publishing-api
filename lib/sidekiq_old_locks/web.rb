require "sidekiq_old_locks/web/helpers"

module SidekiqOldLocks
  module Web
    def self.registered(app)
      app.helpers SidekiqOldLocks::Web::Helpers

      app.get "/old_locks" do
        @locks = old_digests
        @default_ttl = "#{SidekiqUniqueJobs.config.lock_ttl / 60} minutes"

        erb(File.read(Rails.root.join("app/views/sidekiq/old_locks.html.erb")))
      end

      app.get "/old_locks/:digest" do
        @digest = safe_route_params(:digest)
        @retry_set_data = old_digest_retry_set_data(@digest)

        erb(File.read(Rails.root.join("app/views/sidekiq/old_lock.html.erb")))
      end
    end
  end
end

begin
  require "delegate" unless defined?(DelegateClass)
  require "sidekiq/web" unless defined?(Sidekiq::Web)

  if Sidekiq::MAJOR >= 8
    Sidekiq::Web.configure do |config|
      config.register_extension(
        SidekiqOldLocks::Web,
        name: "unique_jobs_custom",
        tab: ["Old Locks"],
        index: %w[old_locks/],
      )
    end
  else
    Sidekiq::Web.register(SidekiqOldLocks::Web)
    Sidekiq::Web.tabs["Old Locks"] = "old_locks"
  end
rescue NameError, LoadError => e
  SidekiqUniqueJobs.logger.error(e)
end
