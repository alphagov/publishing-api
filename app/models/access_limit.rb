class AccessLimit < ActiveRecord::Base
  belongs_to :content_item

  validate :user_uids_are_strings

private

  def user_uids_are_strings
    unless users.all? { |id| id.is_a?(String) }
      errors.set(:users, ["contains non-string user UIDs"])
    end
  end
end
