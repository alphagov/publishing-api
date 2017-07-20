class LinkExpansion::EditionHash
  class << self
    def from(values)
      return nil unless values.present?
      hash = values.is_a?(Array) ? hash_for(values) : values
      hash = SymbolizeJSON.symbolize(hash)
      hash = hash.slice(*edition_fields)
      hash[:api_path] = api_path(hash) unless hash[:base_path].nil?
      hash[:withdrawn] = withdrawn?(hash)
      hash.except(:id, :"unpublishings.type")
    end

    def edition_fields
      LinkExpansion::Rules::DEFAULT_FIELDS_WITH_DETAILS +
        %i[id state unpublishings.type] -
        %i[api_path withdrawn]
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
      unpublishing_type = hash[:"unpublishings.type"]
      return false if unpublishing_type.nil?
      unpublishing_type == "withdrawal"
    end
  end
end
