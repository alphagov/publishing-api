module LinkExpansion::HashedEdition
  def edition_hash(values)
    return nil unless values.present?
    hash = values.is_a?(Array) ? hash_for(values) : values
    hash = SymbolizeJSON.symbolize(hash)
    hash = hash.slice(*edition_fields)
    hash[:api_path] = api_path(hash) unless hash[:base_path].nil?
    hash[:withdrawn] = withdrawn?(hash)
    hash.except(:id)
  end

  def edition_fields
    fields = LinkExpansion::Rules::DEFAULT_FIELDS_WITH_DETAILS.dup
    fields << :id << :state << :"unpublishings.type"
    fields -= %i[api_path withdrawn]
    fields
  end

private

  def hash_for(values)
    return nil unless values.present?
    Hash[edition_fields.zip(values)]
  end


  def api_path(hash)
    "/api/content" + hash[:base_path]
  end

  def withdrawn?(hash)
    unpublishing_type = hash.delete(:"unpublishings.type")
    return false unless hash[:state] == "unpublished"
    return false if unpublishing_type.nil?
    unpublishing_type == "withdrawal"
  end
end
