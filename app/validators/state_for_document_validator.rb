class StateForDocumentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.state && record.document && %w[draft published unpublished].include?(record.state)

    criteria = {
      document: record.document,
      state: record.state == "draft" ? "draft" : %w[published unpublished],
    }

    conflict_id = Edition.where(criteria).where.not(id: record.id).pick(:id)

    if conflict_id
      error = "state=#{record.state} and document=#{record.document_id} "\
        "conflicts with edition id=#{conflict_id}"
      record.errors.add(:base, error)
    end
  end
end
