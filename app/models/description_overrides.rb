# Postgres's JSON columns have problems storing literal strings, so these
# getters/setters wrap the description in a JSON object.

module DescriptionOverrides
  extend ActiveSupport::Concern

  included do
    def description=(value)
      super(value: value)
    end

    def description
      super.fetch(:value)
    end

    def attributes
      attributes = super
      description = attributes.delete("description")

      if description
        attributes.merge("description" => description.fetch("value"))
      else
        attributes
      end
    end
  end

  class_methods do
    def column_defaults
      super.merge("description" => nil)
    end
  end
end
