class VersionForDocumentValidator < ActiveModel::Validator
  def validate(record)
    return unless record.document && record.user_facing_version

    criteria = {
      document: record.document,
      user_facing_version: record.user_facing_version,
    }

    conflict = ContentItem.where(criteria).where.not(id: record.id).order(nil).first

    if conflict
      error = "user_facing_version=#{record.user_facing_version} and "
      error << "document=#{record.document_id} conflicts with content item "
      error << "id=#{conflict[:id]}"
      record.errors.add(:base, error)
    end
  end
end
