class EmbeddedContentFinderService
  def fetch_linked_content_ids(details, locale)
    content_references = details.values.map { |value|
      find_content_references(value)
    }.flatten.compact.uniq

    check_all_references_exist(content_references, locale)
    content_references.map(&:content_id)
  end

  def find_content_references(value)
    case value
    when Array
      value.map { |item| find_content_references(item) }.flatten
    when Hash
      value.map { |_, v| find_content_references(v) }.flatten
    when String
      Govspeak::EmbedExtractor.new(value).content_references
    else
      []
    end
  end

private

  def check_all_references_exist(content_references, locale)
    found_editions = live_editions(content_references, locale)
    if found_editions.count != content_references.count
      not_found_content_ids = content_references.map(&:content_id) - found_editions.map(&:content_id)
      raise CommandError.new(
        code: 422,
        message: "Could not find any live editions in locale #{locale} for: #{not_found_content_ids.join(', ')}, ",
      )
    end
  end

  def live_editions(content_references, locale)
    Edition.with_document.where(
      state: "published",
      content_store: "live",
      document_type: content_references.map(&:document_type),
      documents: { content_id: content_references.map(&:content_id), locale: },
    )
  end
end
