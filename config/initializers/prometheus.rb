require "govuk_app_config/govuk_prometheus_exporter"
require "collectors/sidekiq_old_locks_collector"

GovukPrometheusExporter.configure(collectors: [Collectors::SidekiqOldLocksCollector])
