class VersionForDocumentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.document && record.user_facing_version

    criteria = {
      document: record.document,
      user_facing_version: record.user_facing_version,
    }

    conflict = Edition.where(criteria).where.not(id: record.id).order(nil).first

    if conflict
      error = "user_facing_version=#{record.user_facing_version} and "\
        "document=#{record.document_id} conflicts with edition "\
        "id=#{conflict[:id]}"
      record.errors.add(:base, error)
    end
  end
end
