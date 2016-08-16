class StateForLocaleValidator < ActiveModel::Validator
  def validate(record)
    return unless record.content_item

    content_item = record.content_item
    state = content_item_state(record)
    locale = content_item_locale(record)

    return unless state && locale && %w(draft published unpublished).include?(state)

    conflict = Queries::StateForLocale.conflict(
      content_item.id,
      content_item.content_id,
      state,
      locale
    )

    if conflict
      error = "state=#{state} and locale=#{locale} for content "
      error << "item=#{content_item.content_id} conflicts with content "
      error << "item id=#{conflict[:id]}"
      record.errors.add(:content_item, error)
    end
  end

private

  def content_item_state(record)
    return record.name if record.is_a?(State)
    State.where(content_item: record.content_item).pluck(:name).first
  end

  def content_item_locale(record)
    return record.locale if record.is_a?(Translation)
    Translation.where(content_item: record.content_item).pluck(:locale).first
  end
end
