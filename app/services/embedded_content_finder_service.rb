class EmbeddedContentFinderService
  def fetch_linked_content_ids(details, locale)
    content_references = details.values.map { |value|
      find_content_references(value)
    }.flatten.compact

    live_content_ids(content_references, locale)
  end

  def find_content_references(value)
    case value
    when Array
      value.map { |item| find_content_references(item) }.flatten
    when Hash
      value.map { |_, v| find_content_references(v) }.flatten
    when String
      ContentBlockTools::ContentBlockReference.find_all_in_document(value)
    else
      []
    end
  end

private

  def live_content_ids(content_references, locale)
    found_editions = live_editions(content_references.uniq, locale)
    not_found_content_ids = content_references.map(&:content_id) - found_editions.map(&:content_id)

    if not_found_content_ids.any?
      Sentry.capture_exception(CommandError.new(
                                 code: 422,
                                 message: "Could not find any live editions for embedded content IDs: #{not_found_content_ids.join(', ')}",
                               ))
    end
    content_references.map(&:content_id) - not_found_content_ids
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
