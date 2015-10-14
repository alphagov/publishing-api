class BasePathValidator < ActiveModel::Validator
  def validate(record)
    live_item = LiveContentItem.find_by(content_id: record.content_id)

    if live_item.present? && live_item.base_path != record.base_path
      record.errors.add(:base_path, 'is immutable for published items')
    end
  end
end
