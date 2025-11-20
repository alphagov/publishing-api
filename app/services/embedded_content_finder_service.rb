class EmbeddedContentFinderService
  def fetch_linked_content_ids(details)
    content_references = details.values.map { |value|
      find_content_references(value)
    }.flatten.compact

    live_content_ids(content_references)
  end

  def find_content_references(value)
    case value
    when Array
      value.map { |item| find_content_references(item) }.flatten
    when Hash
      value.map { |_, v| find_content_references(v) }.flatten
    when String
      content_references = ContentBlockTools::ContentBlockReference.find_all_in_document(value)
      transform_aliases_to_content_ids(content_references)
    else
      []
    end
  end

private

  def live_content_ids(content_references)
    found_content_ids = live_editions(content_references.uniq)
                        .pluck({ documents: :content_id })
    identifiers = content_references.map(&:identifier)
    not_found_content_ids = identifiers - found_content_ids

    if not_found_content_ids.any?
      log_error "Could not find any live editions for embedded content IDs: #{not_found_content_ids.join(', ')}"
      identifiers - not_found_content_ids
    else
      identifiers
    end
  end

  def transform_aliases_to_content_ids(content_references)
    ContentReferenceIdentifierNormaliser.new(content_references: content_references).call
  end

  def live_editions(content_references)
    Edition.with_document.where(
      state: "published",
      content_store: "live",
      document_type: content_references.map(&:document_type),
      documents: { content_id: content_references.map(&:identifier) },
    )
  end

  def log_error(message)
    GovukError.notify(
      CommandError.new(
        code: 422,
        message:,
      ),
    )
  end

  class ContentReferenceIdentifierNormaliser
    def initialize(content_references:)
      @content_references = content_references
    end

    def call
      content_references.map { |reference|
        if reference.identifier_is_alias?
          replace_alias_content_id_with_content_id(reference)
        else
          reference
        end
      }.compact
    end

  private

    attr_reader :content_references

    def content_id_aliases
      @content_id_aliases ||= ContentIdAlias.where(name: detected_aliases).map { |a| [a.name, a.content_id] }.to_h
    end

    def detected_aliases
      content_references.select(&:identifier_is_alias?).map(&:identifier)
    end

    def replace_alias_content_id_with_content_id(reference)
      identifier = content_id_aliases[reference.identifier]
      if identifier.nil?
        log_error "Could not find a Content ID for alias #{reference.identifier}"
        return
      end

      ContentBlockTools::ContentBlockReference.new(
        **reference.to_h.merge(identifier: identifier),
      )
    end

    def log_error(message)
      GovukError.notify(
        CommandError.new(
          code: 422,
          message:,
        ),
      )
    end
  end
end
