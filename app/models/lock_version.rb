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


  def copy_version_from(target)
    lock_version = LockVersion.find_by!(target: target)
    self.number = lock_version.number
  end

  def conflicts_with?(previous_version_number)
    return false if previous_version_number.nil?

    self.number != previous_version_number.to_i
  end

  def self.in_bulk(items, type)
    id_list = items.reject(&:blank?).map(&:id)
    self.where(target: id_list, target_type: type.to_s).index_by(&:target_id)
  end

private

  def content_item_target?
    target_type == 'ContentItem'
  end
end
