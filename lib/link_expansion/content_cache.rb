class LinkExpansion::ContentCache
  def initialize(with_drafts:, locale:, preload_content_ids: [])
    @with_drafts = with_drafts
    @locale = locale
    @store = editions(preload_content_ids)
  end

  def find(content_id)
    if store.has_key?(content_id)
      store[content_id]
    else
      store[content_id] = edition(content_id)
    end
  end

private

  attr_reader :store, :with_drafts, :locale

  def edition(content_id)
    editions([content_id])[content_id]
  end

  def locale_fallback_order
    [locale, Edition::DEFAULT_LOCALE].uniq
  end

  def editions(content_ids)
    return {} unless content_ids.present?
    results = Hash[content_ids.map { |id| [id, nil] }]
    edition_ids = Queries::GetEditionIdsWithFallbacks.(content_ids,
      locale_fallback_order: locale_fallback_order,
      state_fallback_order: state_fallback_order,
    )
    Edition.where(id: edition_ids)
      .each_with_object(results) { |item, memo| memo[item.content_id] = item }
  end

  def state_fallback_order
    with_drafts ? %i[draft published withdrawn] : %i[published withdrawn]
  end
end
