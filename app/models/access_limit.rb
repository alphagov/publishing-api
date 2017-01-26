class AccessLimit < ApplicationRecord
  belongs_to :edition, foreign_key: "content_item_id"

  validate :user_uids_are_strings

private

  def user_uids_are_strings
    unless users.all? { |id| id.is_a?(String) }
      errors.add(:users, ["contains non-string user UIDs"])
    end
  end
end
