class BasePathValidator < ActiveModel::Validator
  def validate(record)
    unless record.mutable_base_path?
      live_item = LiveContentItem.find_by(
        content_id: record.content_id,
        locale: record.locale,
      )

      if live_item.present? && live_item.base_path != record.base_path
        record.errors.add(:base_path, 'cannot be changed for published items')
      end
    end
  end
end
