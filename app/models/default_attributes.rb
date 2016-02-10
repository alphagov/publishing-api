module DefaultAttributes
  extend ActiveSupport::Concern

  included do
    def assign_attributes_with_defaults(attributes)
      new_attributes = self.class.column_defaults.symbolize_keys
        .merge(attributes.symbolize_keys)
        .except(:id, :version, :created_at, :updated_at)
      assign_attributes(new_attributes)
    end
  end
end
