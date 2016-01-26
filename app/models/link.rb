class Link < ActiveRecord::Base
  include SymbolizeJSON

  belongs_to :link_set

  validate :link_type_is_valid
  validate :content_id_is_valid

  def target_content_id
    passthrough_hash || super
  end

  def target_content_id=(string_or_hash)
    case string_or_hash
    when String
      super
    when Hash
      self.passthrough_hash = string_or_hash
    end
  end

private

  def link_type_is_valid
    unless link_type.match(/\A[a-z0-9_]+\z/) && link_type != "available_translations"
      errors[:link] = "Invalid link type: #{link_type}"
    end
  end

  def content_id_is_valid
    unless target_content_id.is_a?(Hash) || UuidValidator.valid?(target_content_id)
      errors[:link] = "target_content_id must be a valid UUID"
    end
  end
end
