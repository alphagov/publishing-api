class Link < ActiveRecord::Base
  belongs_to :link_set

  validate :link_type_is_valid
  validate :content_id_is_valid

private

  def link_type_is_valid
    unless link_type.match(/\A[a-z0-9_]+\z/) && link_type != "available_translations"
      errors[:link] = "Invalid link type: #{link_type}"
    end
  end

  def content_id_is_valid
    unless UuidValidator.valid?(target_content_id)
      errors[:link] = "target_content_id must be a valid UUID"
    end
  end
end
