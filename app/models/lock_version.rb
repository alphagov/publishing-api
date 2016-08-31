class LockVersion < ActiveRecord::Base
  include Version
  belongs_to :target, polymorphic: true

  def self.join_content_items(content_item_scope)
    content_item_scope.joins(
      "INNER JOIN lock_versions ON
        lock_versions.target_id = content_items.id AND
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
