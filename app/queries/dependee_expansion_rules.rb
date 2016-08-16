module Queries
  module DependeeExpansionRules
    extend DependentExpansionRules
    extend self

  private

    def custom(link_type)
      {
        redirect: [],
        topical_event: default_fields + [:details],
        placeholder_topical_event: default_fields + [:details],
        organisation: default_fields + [:details],
        placeholder_organisation: default_fields + [:details],
      }[link_type]
    end
  end
end
