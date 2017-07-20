class LinkExpansion::ContentCache
  def initialize(with_drafts:, locale:, preload_editions: [], preload_content_ids: [])
    @with_drafts = with_drafts
    @locale = locale
    @store = build_store(preload_editions, preload_content_ids)
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

  def build_store(editions, content_ids)
    store = Hash[editions.map { |edition| [edition.content_id, edition_hash.from(edition.attributes)] }]

    to_preload = content_ids - editions.map(&:content_id)
    editions(to_preload).each_with_object(store) do |edition_values, hash|
      attrs = edition_hash.from(edition_values)
      hash[attrs[:content_id]] = attrs
    end
  end

  def edition(content_id)
    edition_hash.from(editions([content_id]).first)
  end

  def locale_fallback_order
    [locale, Edition::DEFAULT_LOCALE].uniq
  end

  def editions(content_ids)
    return [] unless content_ids.present?
    edition_ids = Queries::GetEditionIdsWithFallbacks.(content_ids,
      locale_fallback_order: locale_fallback_order,
      state_fallback_order: state_fallback_order,
    )
    Edition
      .joins(
        <<-SQL.strip_heredoc
          LEFT OUTER JOIN unpublishings
          ON unpublishings.edition_id = editions.id
          AND editions.state = 'unpublished'
        SQL
      )
      .with_document
      .includes(:document)
      .where(id: edition_ids)
      .pluck(*edition_hash.edition_fields)
  end

  def state_fallback_order
    with_drafts ? %i[draft published withdrawn] : %i[published withdrawn]
  end

  def edition_hash
    LinkExpansion::EditionHash
  end
end
