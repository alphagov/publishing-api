class EmbeddedContentFinderService
  ContentReference = Data.define(:document_type, :friendly_id, :embed_code)

  SUPPORTED_DOCUMENT_TYPES = %w[contact content_block_email_address].freeze
  # UUID_REGEX = /([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})/
  EMBED_REGEX = /({{embed:(#{SUPPORTED_DOCUMENT_TYPES.join('|')}):(.*?)}})/

  def fetch_linked_friendly_ids(body, locale)
    content_references = if body.is_a?(Array)
                           body.map { |hash| find_content_references(hash["content"]) }.flatten
                         else
                           find_content_references(body)
                         end
    return [] if content_references.empty?

    get_content_ids_for_content_references(content_references, locale)
  end

  def find_content_references(body)
    body.scan(EMBED_REGEX).map { |match| ContentReference.new(document_type: match[1], friendly_id: match[2], embed_code: match[0]) }.uniq
  end

private

  def get_content_ids_for_content_references(content_references, locale)
    puts content_references.inspect
    embedded_content_references = EmbeddedContentReference.where(friendly_id: content_references.map(&:friendly_id))
    content_ids = embedded_content_references.map(&:content_id)

    found_editions = Edition.with_document.where(
      state: "published",
      content_store: "live",
      document_type: content_references.map(&:document_type),
      documents: { content_id: content_ids, locale: },
    )

    if found_editions.count != content_references.count
      not_found_content_references = content_ids - found_editions.map(&:content_id)
      raise CommandError.new(
        code: 422,
        message: "Could not find any live editions in locale #{locale} for: #{not_found_content_references.join(', ')}, ",
      )
    end

    embedded_content_references.map(&:content_id)
  end
end
