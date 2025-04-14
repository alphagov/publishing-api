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
    found_editions = live_editions(content_references.uniq)
    not_found_content_ids = content_references.map(&:identifier) - found_editions.map(&:content_id)

    if not_found_content_ids.any?
      GovukError.notify(CommandError.new(
                          code: 422,
                          message: "Could not find any live editions for embedded content IDs: #{not_found_content_ids.join(', ')}",
                        ))
    end
    content_references.map(&:identifier) - not_found_content_ids
  end

  def transform_aliases_to_content_ids(content_references)
    embedded_aliases = content_references.select(&:identifier_is_alias?).map(&:identifier)
    content_id_aliases = ContentIdAlias.where(name: embedded_aliases).map { |a| [a.name, a.content_id] }.to_h
    content_references.map do |reference|
      if reference.identifier_is_alias?
        identifier = content_id_aliases[reference.identifier]
        if identifier.nil?
          GovukError.notify(
            CommandError.new(
              code: 422,
              message: "Could not find a Content ID for alias #{reference.identifier}",
            ),
          )
          next
        end
        ContentBlockTools::ContentBlockReference.new(
          **reference.to_h.merge(identifier:),
        )
      else
        reference
      end
    end
  end

  def live_editions(content_references)
    Edition.with_document.where(
      state: "published",
      content_store: "live",
      document_type: content_references.map(&:document_type),
      documents: { content_id: content_references.map(&:identifier) },
    )
  end
end
