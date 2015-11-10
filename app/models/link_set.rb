class LinkSet < ActiveRecord::Base
  # This has been introduced for avoiding clashes with the `Link` column.
  # Remove this line when dropping the column.
  has_many :content_item_links, :class_name => 'Link', dependent: :destroy

  include Replaceable
  include DefaultAttributes
  include SymbolizeJSON

  validate :links_are_valid

  def links=(links_hash)
    super(links_hash || {})
  end

private
  def self.query_keys
    [:content_id]
  end

  def links_are_valid
    # Test that the `links` attribute, if set, is a hash from strings to lists
    # of UUIDs
    return if links.empty?

    bad_keys = links.keys.reject { |key| link_key_is_valid?(key) }
    if bad_keys.any?
      errors[:links] = "Invalid link types: #{bad_keys.to_sentence}"
    end

    bad_values = links.values.reject { |value|
      value.is_a?(Array) && value.all? { |content_id|
        UuidValidator.valid?(content_id)
      }
    }
    if bad_values.any?
      errors[:links] = "must map to lists of UUIDs"
    end
  end

  def link_key_is_valid?(link_key)
    link_key.is_a?(Symbol) &&
      link_key.to_s.match(/\A[a-z0-9_]+\z/) &&
      link_key != :available_translations
  end
end
