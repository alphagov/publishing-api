class EmbeddedContentFinderService
  ContentReference = Data.define(:document_type, :content_id, :embed_code)

  SUPPORTED_DOCUMENT_TYPES = %w[contact].freeze
  UUID_REGEX = /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
  EMBED_REGEX = /({{embed:(#{SUPPORTED_DOCUMENT_TYPES.join('|')}):#{UUID_REGEX}}})/

  def fetch_linked_content_ids(body, locale)
    content_references = if body.is_a?(Array)
                           body.map { |hash| find_content_references(hash[:content]) }.flatten
                         else
                           find_content_references(body)
                         end
    return [] if content_references.empty?

    check_all_references_exist(content_references, locale)
    content_references.map(&:content_id)
  end

  def find_content_references(body)
    body.scan(EMBED_REGEX).map { |match| ContentReference.new(document_type: match[1], content_id: match[2], embed_code: match[0]) }.uniq
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
