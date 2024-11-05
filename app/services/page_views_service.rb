require "google/cloud/bigquery"
require "googleauth"

class PageViewsService
  PageView = Data.define(:path, :page_views)
  SQL = <<~SQL.freeze
    SELECT cleaned_page_location,
    COUNT (DISTINCT unique_session_id) as unique_pageviews FROM
    (
      SELECT cleaned_page_location, unique_session_id
      FROM `ga4-analytics-352613.flattened_dataset.partitioned_flattened_events`
      WHERE event_name = "page_view"
      AND cleaned_page_location IN UNNEST(@paths)
      AND event_date BETWEEN @start_date AND @end_date
    )
    GROUP BY cleaned_page_location
  SQL
  SCOPE = ["https://www.googleapis.com/auth/bigquery"].freeze

  def initialize(paths:)
    @paths = paths
    @end_date = Time.zone.today
    @start_date = @end_date - 30.days
  end

  def call
    if credentials_not_supplied?
      Rails.logger.info("BigQuery credentials not found - skipping job")
      return []
    end

    results.map do |row|
      PageView.new(path: row[:cleaned_page_location], page_views: row[:unique_pageviews])
    end
  end

private

  attr_reader :paths, :start_date, :end_date

  def results
    @results ||= bigquery.query SQL, params: { paths:, start_date: start_date.iso8601, end_date: end_date.iso8601 }
  end

  def bigquery
    @bigquery ||= ::Google::Cloud::Bigquery.new(
      project_id: ENV["BIGQUERY_PROJECT_ID"],
      credentials: ::Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(credentials.to_json),
        scope: SCOPE,
      ),
    )
  end

  def credentials
    {
      "client_email" => ENV["BIGQUERY_CLIENT_EMAIL"],
      "private_key" => ENV["BIGQUERY_PRIVATE_KEY"],
    }
  end

  def credentials_not_supplied?
    ENV["BIGQUERY_PROJECT_ID"].blank? && ENV["BIGQUERY_CLIENT_EMAIL"].blank? && ENV["BIGQUERY_PRIVATE_KEY"].blank?
  end
end
