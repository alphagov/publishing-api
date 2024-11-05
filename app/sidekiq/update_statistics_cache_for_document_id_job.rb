class UpdateStatisticsCacheForDocumentIdJob
  include Sidekiq::Job

  def perform(document_id)
    document = Document.find(document_id)
    base_path = document.live.base_path

    Rails.logger.info("Fetching page views for #{base_path}")
    result = PageViewsService.new(paths: [base_path]).call
                             .find { |r| r.path == base_path }

    if result.nil?
      Rails.logger.info("No data found for #{base_path} - skipping")
      return
    end

    Rails.logger.info("Updating statistics for #{base_path}")
    StatisticsCache.upsert(
      {
        document_id: document.id,
        unique_pageviews: result.page_views,
      },
      unique_by: [:document_id],
    )
  end
end
