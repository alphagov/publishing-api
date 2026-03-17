# frozen_string_literal: true

module Types
  class QueryType
    class EditionTypeOrSubtype < Types::BaseUnion
      EDITION_TYPES = [
        Types::EditionType,
        Types::MinistersIndexType,
      ].freeze

      possible_types(*EDITION_TYPES)

      class << self
        def resolve_type(object, _context)
          matching_edition_subtype = Types::EditionType.descendants.find do |edition_subtype|
            edition_subtype.relevant_schemas_and_document_types[object.schema_name]&.include?(object.document_type)
          end

          matching_edition_subtype || Types::EditionType
        end
      end
    end
  end
end
