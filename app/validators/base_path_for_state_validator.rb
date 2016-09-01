class BasePathForStateValidator < ActiveModel::Validator
  def validate(record)
    return unless record.content_item

    state = content_item_state(record)
    base_path = content_item_base_path(record)

    return unless state && base_path

    check_conflict(record, state, base_path)
  end

private

  def content_item_state(record)
    return record.name if record.is_a?(State)
    State.where(content_item: record.content_item).pluck(:name).first
  end

  def content_item_base_path(record)
    return record.base_path if record.is_a?(Location)
    Location.where(content_item: record.content_item).pluck(:base_path).first
  end

  def check_conflict(record, state, base_path)
    id = record.content_item.id
    conflict = Queries::BasePathForState.conflict(id, state, base_path)
    if conflict
      record.errors.add(:content_item, error_message(base_path, conflict))
    end
  end

  def error_message(base_path, conflict)
    message = "base path=#{base_path} conflicts with content_id=#{conflict[:content_id]}"
    message << " and locale=#{conflict[:locale]}" if conflict[:locale]
    message
  end
end
