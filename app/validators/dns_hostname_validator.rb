class DnsHostnameValidator < ActiveModel::EachValidator
  DNS_HOSTNAME_PATTERN = /\A[a-z0-9\-_]*\z/.freeze

  def validate_each(record, attribute, value)
    unless value && value.match(DNS_HOSTNAME_PATTERN)
      record.errors.add(attribute, "is not a valid dns hostname")
    end
  end
end
