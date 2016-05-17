module Queries
  module DependeeExpansionRules
    extend DependentExpansionRules
    extend self

  private

    def custom(link_type)
      {}[link_type]
    end
  end
end
