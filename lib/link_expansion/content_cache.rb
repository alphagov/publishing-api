class LinkExpansion::ContentCache
  def initialize(with_drafts:, locale:, preload_editions: [], preload_content_ids: [])
    @with_drafts = with_drafts
    @locale = locale
    @cache = build_cache(preload_editions, preload_content_ids)
  end

  def find(content_id)
    if cache.key?(content_id)
      cache[content_id]
    else
      cache[content_id] = load_uncached_edition(content_id)
    end
  end

private

  attr_reader :cache, :with_drafts, :locale

  def build_cache(preload_editions, preload_content_ids)
    cached_editions = Hash[preload_editions.map { |edition| [edition.content_id, LinkExpansion::EditionHash.from(edition)] }]

    to_preload = preload_content_ids - preload_editions.map(&:content_id)
    fetch_editions_from_database(to_preload).each_with_object(cached_editions) do |edition_values, hash|
      attrs = LinkExpansion::EditionHash.from(edition_values)
      hash[attrs[:content_id]] = attrs
    end

    # fill in where the preloading didn't find a result
    (to_preload - cached_editions.keys).each_with_object(cached_editions) do |content_id, hash|
      hash[content_id] = nil
    end
  end

  def load_uncached_edition(content_id)
    LinkExpansion::EditionHash.from(fetch_editions_from_database([content_id]).first)
  end

  def locale_fallback_order
    [locale, Edition::DEFAULT_LOCALE].uniq
  end

  def fetch_editions_from_database(content_ids)
    return [] if content_ids.blank?

    edition_ids = Queries::GetEditionIdsWithFallbacks.call(content_ids,
                                                           locale_fallback_order: locale_fallback_order,
                                                           state_fallback_order: state_fallback_order)
    return [] unless edition_ids

    Edition
      .joins(
        <<-SQL.strip_heredoc,
          LEFT OUTER JOIN unpublishings
          ON unpublishings.edition_id = editions.id
          AND editions.state = 'unpublished'
        SQL
      )
      .with_document
      .where(id: edition_ids)
      .pluck(*ExpansionRules::POSSIBLE_FIELDS_FOR_LINK_EXPANSION)
  end

  def state_fallback_order
    with_drafts ? %i[draft published withdrawn] : %i[published withdrawn]
  end
end
