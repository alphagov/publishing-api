class Link < ActiveRecord::Base
  belongs_to :link_set

  include Replaceable
  include DefaultAttributes

  validate :link_is_valid

private
  def link_is_valid
    # Test that:
    # - the `link_type` attribute is valid
    # - the `target_content_id` attribute is a UUID

    unless link_type_is_valid?(link_type)
      errors[:link] = "Invalid link type: #{link_type}"
    end

    unless UuidValidator.valid?(target_content_id)
      errors[:link] = "target_content_id must be a valid UUID"
    end
  end

  def link_type_is_valid?(link_type)
    link_type.match(/\A[a-z0-9_]+\z/) && link_type != "available_translations"
  end
end
