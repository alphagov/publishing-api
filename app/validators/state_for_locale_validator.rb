class StateForLocaleValidator < ActiveModel::Validator
  def validate(record)
    return unless record.state && record.locale && %w(draft published unpublished).include?(record.state)

    criteria = {
      document: record.document,
      state: record.state == "draft" ? "draft" : %w(published unpublished),
    }

    conflict = ContentItem.where(criteria).where.not(id: record.id).first

    if conflict
      error = "state=#{record.state} and locale=#{record.locale} "
      error << "for content item=#{record.content_id} conflicts with "
      error << "content item id=#{conflict[:id]}"
      record.errors.add(:base, error)
    end
  end
end
