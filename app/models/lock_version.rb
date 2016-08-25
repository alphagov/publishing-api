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
    target.is_a?(ContentItem)
  end

  def draft_and_live_versions
    draft = ContentItemFilter.similar_to(target, state: "draft", user_version: nil).first
    live = ContentItemFilter.similar_to(target, state: "published", user_version: nil).first

    if draft == target
      draft_version = self
      live_version = self.class.find_by(target: live)
    elsif live == target
      draft_version = self.class.find_by(target: draft)
      live_version = self
    end

    [draft_version, live_version]
  end
end
