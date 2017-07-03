class ExpandedLinkSetCacheWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  def perform(content_id, with_drafts: false)
    locales_for(content_id).each do |locale|
      cache_key = ["expanded-link-set", content_id, locale, with_drafts]
      presenter = Presenters::Queries::ExpandedLinkSet.by_content_id(content_id,
                                                                     locale: locale,
                                                                     with_drafts: with_drafts)
      Rails.cache.write(cache_key, presenter.links)
    end
  end

private

  def locales_for(content_id)
    Document.where(content_id: content_id).pluck(:locale)
  end
end
