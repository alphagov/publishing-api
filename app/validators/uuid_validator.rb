class UuidValidator < ActiveModel::EachValidator

  # This pattern matches a subset of UUIDs compatible with RFC4122, in that it
  # insists on lowercase, hyphenated UUIDs, for example:
  #
  #     a2c4477b-90fa-4838-a989-ca6004462c04
  #
  # By being overly strict about representations, we can avoid problems with
  # people trying to compare UUIDs by case-sensitive string comparison.
  UUID_PATTERN = %r{
    \A
    [a-f\d]{8}
    -
    [a-f\d]{4}
    -
    [1-5]   # Version: http://tools.ietf.org/html/rfc4122#section-4.1.3
    [a-f\d]{3}
    -
    [89ab]  # Variant: http://tools.ietf.org/html/rfc4122#section-4.1.1
    [a-f\d]{3}
    -
    [a-f\d]{12}
    \z
  }x

  def validate_each(record, attribute, value)
    unless self.class.valid?(value)
      message = options[:message] || "is not a canonical UUID"
      record.errors[attribute] << message
    end
  end

  def self.valid?(value)
    value =~ UUID_PATTERN
  end
end
