class UpdateStatisticsCachesJob
  include Sidekiq::Job

  BATCH_SIZE = 50

  def perform
    Rails.logger.info("Processing #{links.length} link(s) in batches of #{BATCH_SIZE}")
    links.each_slice(BATCH_SIZE).with_index do |slice, i|
      Rails.logger.info("Processing batch #{i}")
      editions = slice.map(&:edition)
      page_views_for_slice = page_views(editions.map(&:base_path))
      statistics_caches = page_views_for_slice.map do |result|
        edition = editions.find { |e| e.base_path == result.path }
        {
          document_id: edition.document.id,
          unique_pageviews: result.page_views,
        }
      end
      Rails.logger.info("Updating Statistics caches")
      StatisticsCache.upsert_all(statistics_caches, unique_by: [:document_id])
    end
  end

private

  def page_views(base_paths)
    Rails.logger.info("Fetching page views")
    PageViewsService.new(paths: base_paths).call
  end

  def links
    Link.includes(edition: [:document]).where(link_type: "embed", edition: { state: "published" })
  end
end
