class LockVersion < ApplicationRecord
  include Version
  belongs_to :target, polymorphic: true

  after_save do
    item = lock_version_target
    item.update_column(:stale_lock_version, number) if item && number > item.stale_lock_version
  end

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

  def lock_version_target
    if content_item_target?
      target.document
    else
      target
    end
  end

private

  def content_item_target?
    target_type == 'ContentItem'
  end
end
