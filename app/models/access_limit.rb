class AccessLimit < ActiveRecord::Base
  # These are to be removed after deploy
  belongs_to :target, polymorphic: true
  deprecated_columns :target_id, :target_type
  # These are to be removed after deploy

  belongs_to :content_item

  validate :user_uids_are_strings

  def self.viewable?(target, user_uid: nil)
    if (access_limit = self.find_by(content_item: target))
      user_uid.present? && access_limit.users.include?(user_uid)
    else
      true
    end
  end

private

  def user_uids_are_strings
    unless users.all? { |id| id.is_a?(String) }
      errors.set(:users, ["contains non-string user UIDs"])
    end
  end
end
