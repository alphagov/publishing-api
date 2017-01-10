class LockVersion < ApplicationRecord
  include Version
  belongs_to :target, polymorphic: true

  def self.join_editions(scope)
    scope.joins(
      "INNER JOIN lock_versions ON
        lock_versions.target_id = editions.id AND
        lock_versions.target_type = 'ContentItem'"
    )
  end

  def conflicts_with?(previous_version_number)
    return false if previous_version_number.nil?

    self.number != previous_version_number.to_i
  end

private

  def content_item_target?
    target_type == 'ContentItem'
  end
end
