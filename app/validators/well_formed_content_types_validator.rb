class WellFormedContentTypesValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    @error_messages = []

    validate!(value)

    if @error_messages.present?
      record.errors[attribute] ||= []
      record.errors[attribute].concat(@error_messages)
    end
  end

private

  def validate!(object)
    if object.is_a?(Hash)
      validate_hash!(object)
    elsif object.is_a?(Array)
      validate_array!(object)
    end
  end

  def validate_hash!(hash)
    validate_array!(hash.values)
  end

  def validate_array!(array)
    if has_content_types?(array)
      validate_content!(array)
    else
      array.all? { |e| validate!(e) }
    end
  end

  def has_content_types?(array)
    return false unless array.all? { |v| v.is_a?(Hash) }

    hash_keys = array.flat_map(&:keys).map(&:to_sym)
    hash_keys.include?(:content_type)
  end

  def validate_content!(array)
    array = array.map(&:symbolize_keys)

    validate_that_content_is_present!(array) &&
      validate_that_there_are_no_duplicates!(array) &&
      validate_that_mandatory_content_type_is_present!(array)
  end

  def validate_that_content_is_present!(array)
    array.each do |hash|
      unless hash.key?(:content)
        content_type = hash.fetch(:content_type)
        @error_messages << "the '#{content_type}' content type does not contain content"
      end
    end
  end

  def validate_that_there_are_no_duplicates!(array)
    groups = array.group_by { |hash| hash[:content_type] }
    duplicates = groups.select { |_, hashes| hashes.size > 1 }

    duplicates.each do |content_type, hashes|
      @error_messages << "there are #{hashes.size} instances of the '#{content_type}' content type - there should be 1"
    end
  end

  def validate_that_mandatory_content_type_is_present!(array)
    mandatory_content_type = options[:must_include]
    return true unless mandatory_content_type

    hash = array.detect { |h| h[:content_type] == mandatory_content_type }

    unless hash
      @error_messages << "the '#{mandatory_content_type}' content type is mandatory and it is missing"
    end
  end
end
