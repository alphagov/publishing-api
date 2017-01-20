module DefaultAttributes
  extend ActiveSupport::Concern

  ATTRIBUTES_PROTECTED_FROM_RESET = [
    :id,
    :document_id,
    :content_id,
    :locale,
    :created_at,
    :updated_at,
    :first_published_at,
    :last_edited_at,
  ].freeze

  included do
    def assign_attributes_with_defaults(attributes)
      new_attributes = self.class.column_defaults.symbolize_keys
        .merge(attributes.symbolize_keys)
        .except(*ATTRIBUTES_PROTECTED_FROM_RESET)
      assign_attributes(new_attributes)
    end
  end
end
