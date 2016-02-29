class SchemaNameFormatValidator < ActiveModel::Validator
  def validate(record)
    if record.format.blank? && record.schema_name.blank?
      record.errors.add(:format, 'must be supplied if schema_name is blank')
    elsif record.schema_name.present? && record.document_type.blank?
      record.errors.add(:document_type, 'must be supplied if schema_name is present')
    end
  end
end
