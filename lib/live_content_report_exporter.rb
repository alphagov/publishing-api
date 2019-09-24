require "csv"

class LiveContentReportExporter
  def initialize(publishing_apps)
    @publishing_apps = publishing_apps
  end

  def total
    editions.count
  end

  def file_path
    @file_path ||= Rails.root.join("live_content_report_#{publishing_apps_for_file_path}_#{time_for_file_path}.csv")
  end

  def export(progress: nil)
    CSV.open(file_path, "w") do |csv_out|
      csv_out << csv_headers
      editions.find_each.with_index do |edition, i|
        progress.call(i, total) unless progress.nil?
        csv_out << csv_row(edition)
      end
    end
  end

private

  attr_reader :publishing_apps

  def publishing_apps_for_file_path
    @publishing_apps_for_file_path ||= publishing_apps.join("_")
  end

  def time_for_file_path
    @time_for_file_path ||= Time.zone.now.strftime("%Y%m%d%H%M%S%N")
  end

  def editions
    @editions ||= Edition.
      renderable_content.
      where(phase: "live", state: "published", publishing_app: publishing_apps)
  end

  def csv_headers
    @csv_headers ||= ["URL", "Page title", "Format", "First published at"]
  end

  def csv_row(edition)
    [
      edition.web_url,
      edition.title,
      edition.document_type,
      edition.first_published_at.iso8601,
    ]
  end
end
