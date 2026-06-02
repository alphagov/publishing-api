require "sidekiq_old_locks/web/helpers"

module Collectors
  class SidekiqOldLocksCollector < PrometheusExporter::Server::CollectorBase
    include SidekiqOldLocks::Web::Helpers

    def type
      "publishing_api"
    end

    def metrics
      old_lock_count_gauge = PrometheusExporter::Metric::Gauge.new(
        "publishing_api_old_lock_count",
        "Count of sidekiq-unique-jobs locks that are older than #{SidekiqUniqueJobs.config.lock_ttl.seconds} seconds in Publishing API",
      )
      old_lock_count_gauge.observe(old_digests.count)

      [old_lock_count_gauge]
    end
  end
end
