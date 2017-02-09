class LinkExpansion::ContentCache
  def initialize(with_drafts:, locale_fallback_order:, preload_content_ids: [])
    @with_drafts = with_drafts
    @locale_fallback_order = locale_fallback_order
    @store = web_content_items(preload_content_ids)
  end

  def find(content_id)
    if store.has_key?(content_id)
      store[content_id]
    else
      store[content_id] = web_content_item(content_id)
    end
  end

private

  attr_reader :store, :with_drafts, :locale_fallback_order

  def web_content_item(content_id)
    web_content_items([content_id])[content_id]
  end

  def web_content_items(content_ids)
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
