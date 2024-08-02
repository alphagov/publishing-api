require "prometheus/client"
require "prometheus/client/registry"
require "prometheus/client/formats/text"

namespace :metrics do
  desc "Reports metrics about data in the database to prometheus via the pushgateway"
  task report_to_prometheus: :environment do
    default_labels = { database: "publishing-api" }
    edition_count_dimensions = %i[state content_store document_type publishing_app locale]

    prometheus_registry = Prometheus::Client::Registry.new
    editions_in_database_gauge = prometheus_registry.gauge(
      :editions_in_database_total,
      docstring: "Count of editions in various databases labeled by state, document_type etc.",
      labels: default_labels.keys + edition_count_dimensions,
    )

    edition_counts = Edition
      .with_document
      .where.not(state: "superseded")
      .where.not(content_store: nil)
      .group(*edition_count_dimensions)
      .count

    edition_counts.sort.each do |dimensions, count|
      labels = default_labels.merge(edition_count_dimensions.zip(dimensions).to_h)
      editions_in_database_gauge.set(count, labels:)
    end

    puts "Found #{edition_counts.count} combinations of labels"
    puts Prometheus::Client::Formats::Text.marshal(prometheus_registry)

    pushgateway_url = ENV["PROMETHEUS_PUSHGATEWAY_URL"]
    if pushgateway_url.present?
      puts "Pushing metrics to prometheus via #{pushgateway_url}"
      begin
        Prometheus::Client::Push.new(
          job: "publishing-api-metrics",
          gateway: pushgateway_url,
        ).add(prometheus_registry)
      rescue StandardError => e
        puts e.inspect
        warn e.inspect
        raise e
      end
    end
  end
end
