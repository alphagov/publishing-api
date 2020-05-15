class LinkExpansion::EditionHash
  class << self
    def from(values)
      return nil if values.blank?

      hash = hash_for(values)
      hash = SymbolizeJSON.symbolize(hash)
      hash = hash.slice(*ExpansionRules::POSSIBLE_FIELDS_FOR_LINK_EXPANSION)
      hash[:api_path] = api_path(hash) unless hash[:base_path].nil?
      hash[:withdrawn] = withdrawn?(hash)
      hash.except(:id, :"unpublishings.type")
    end

  private

    def hash_for(values)
      return nil if values.blank?

      case values
      when Array
        Hash[ExpansionRules::POSSIBLE_FIELDS_FOR_LINK_EXPANSION.zip(values)]
      when Edition
        values.attributes.merge(
          content_id: values.content_id,
          locale: values.locale,
        )
      when Hash
        values
      else
        raise ArgumentError, "Values passed to EditionHash.from must be an Array, Edition or Hash."
      end
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
