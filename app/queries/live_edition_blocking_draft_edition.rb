module Queries
  module LiveEditionBlockingDraftEdition
    # Checks for a live edition which would prevent a draft edition with the
    # specified content_id and base_path from being published (from the draft
    # state).
    def self.call(content_id, base_path, document_type)
      return unless base_path

      if SubstitutionHelper::SUBSTITUTABLE_DOCUMENT_TYPES.include?(document_type)
        return # The SubstitionHelper will unpublish any item that is in the way
      end

      conflicts = Edition.with_document
        .where(base_path:, content_store: :live)
        .where.not(documents: { content_id: })
        .where.not(document_type: SubstitutionHelper::SUBSTITUTABLE_DOCUMENT_TYPES)
        .pluck(:id)

      conflicts.first unless conflicts.empty?
    end
  end
end
