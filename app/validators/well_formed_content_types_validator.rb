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
    case object
    when Hash
      validate_hash!(object)
    when Array
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
      validate_that_mandatory_content_types_are_present!(array)
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

  def validate_that_mandatory_content_types_are_present!(array)
    if options[:must_include]
      validate_that_mandatory_content_type_is_present!(array, options[:must_include])
    elsif options[:must_include_one_of]
      validate_that_one_of_the_mandatory_content_types_is_present!(array, Array(options[:must_include_one_of]))
    else
      true
    end
  end

  def validate_that_mandatory_content_type_is_present!(array, mandatory_content_type)
    no_matches = array.none? { |h| h[:content_type] == mandatory_content_type }

    if no_matches
      @error_messages << "the '#{mandatory_content_type}' content type is mandatory and it is missing"
    end
  end

  def validate_that_one_of_the_mandatory_content_types_is_present!(array, optional_content_types)
    return true if optional_content_types.empty?

    no_matches = array.none? { |h| optional_content_types.include?(h[:content_type]) }

    if no_matches
      @error_messages << "there must be at least one content type of (#{optional_content_types.join(', ')})"
    end
  end
end
