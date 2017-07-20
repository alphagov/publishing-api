module LinkExpansion::HashedEdition
  def edition_hash(values)
    return nil unless values.present?
    hash = values.is_a?(Array) ? hash_for(values) : values
    hash = SymbolizeJSON.symbolize(hash)
    hash = hash.slice(*edition_fields)
    hash[:api_path] = api_path(hash) unless hash[:base_path].nil?
    hash[:withdrawn] = withdrawn?(hash)
    hash.delete(:id)
    hash
  end

  def edition_fields
    fields = LinkExpansion::Rules::DEFAULT_FIELDS_WITH_DETAILS.dup << :id << :state
    fields -= %i[api_path withdrawn]
    fields
  end

private

  def hash_for(values)
    return nil unless values.present?
    Hash[edition_fields.zip(values)]
  end


  def api_path(attrs)
    "/api/content" + attrs[:base_path]
  end

  def withdrawn?(attrs)
    return false unless attrs[:state] == "unpublished"
    unpublishing = Unpublishing.find_by(edition_id: attrs[:id])
    return false if unpublishing.nil?
    unpublishing.withdrawal?
  end
end
