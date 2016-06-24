module Queries
  module DependeeExpansionRules
    extend DependentExpansionRules
    extend self

  private

    def custom(link_type)
      {
        organisations: default_fields + [:details],
        html_publication: default_fields + [:schema_name, :document_type],
      }[link_type]
    end
  end
end
