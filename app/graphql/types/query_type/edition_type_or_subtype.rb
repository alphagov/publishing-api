# frozen_string_literal: true

module Types
  class QueryType
    class EditionTypeOrSubtype < Types::BaseUnion
      EDITION_TYPES = [Types::EditionType, Types::RoleType, Types::WorldIndexType, Types::MinistersIndexType].freeze

      possible_types(*EDITION_TYPES)

      class << self
        def resolve_type(object, _context)
          document_type = object.document_type

          matching_edition_subtype = Types::EditionType.descendants.find do |edition_subtype|
            document_type == edition_subtype.document_type
          end

          matching_edition_subtype || Types::EditionType
        end
      end
    end
  end
end
