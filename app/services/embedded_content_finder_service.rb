class EmbeddedContentFinderService
  ContentReference = Data.define(:document_type, :alias, :embed_code)

  SUPPORTED_DOCUMENT_TYPES = %w[contact content_block_email_address].freeze
  EMBED_REGEX = /({{embed:(#{SUPPORTED_DOCUMENT_TYPES.join('|')}):(.*?)}})/

  def fetch_linked_content_ids(details, locale)
    content_references = details.values.map { |value|
      find_content_references(value)
    }.flatten.compact.uniq

    get_content_ids_from_content_references(content_references, locale)
  end

  def find_content_references(value)
    case value
    when Array
      value.map { |item| find_content_references(item) }.flatten
    when Hash
      value.map { |_, v| find_content_references(v) }.flatten
    when String
      value.scan(EMBED_REGEX).map { |match| ContentReference.new(document_type: match[1], alias: match[2], embed_code: match[0]) }.uniq
    else
      []
    end
  end

private

  def get_content_ids_from_content_references(content_references, locale)
    embedded_aliases = content_references.map(&:alias)
    content_id_aliases = ContentIdAlias.where(name: embedded_aliases)

    if content_id_aliases.count != content_references.count
      not_found_aliases = embedded_aliases - content_id_aliases.map(&:name)
      raise CommandError.new(
        code: 422,
        message: "Could not find any live editions in locale #{locale} for: #{not_found_aliases.join(', ')}",
      )
    end

    embedded_content_ids = content_id_aliases.map(&:content_id)
    document_types = content_references.map(&:document_type)

    found_editions = live_editions(embedded_content_ids, document_types, locale)

    if found_editions.count != content_id_aliases.count
      not_found_aliases = content_id_aliases.reject { |ecr| found_editions.map(&:content_id).include?(ecr) }.map(&:name)
      raise CommandError.new(
        code: 422,
        message: "Could not find any live editions in locale #{locale} for: #{not_found_aliases.join(', ')}",
      )
    end

    embedded_content_ids
  end

  def live_editions(content_ids, document_types, locale)
    Edition.with_document.where(
      state: "published",
      content_store: "live",
      document_type: document_types,
      documents: { content_id: content_ids, locale: },
    )
  end
end
