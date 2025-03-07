class VersionForDocumentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.document && record.user_facing_version

    criteria = {
      document: record.document,
      user_facing_version: record.user_facing_version,
    }

    conflict_id = Edition.where(criteria).where.not(id: record.id).pick(:id)

    if conflict_id
      error = "user_facing_version=#{record.user_facing_version} and "\
        "document=#{record.document_id} conflicts with edition "\
        "id=#{conflict_id}"
      record.errors.add(:base, error)
    end
  end
end
