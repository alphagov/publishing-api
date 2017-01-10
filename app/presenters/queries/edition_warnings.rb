module Presenters
  module Queries
    module EditionWarnings
      def self.call(content_id, state, base_path, document_type)
        return unless state == "draft"

        blocking_edition_id = ::Queries::CheckForEditionPreventingDraftFromBeingPublished.call(
          content_id,
          base_path,
          document_type,
        )

        warnings = {}

        if blocking_edition_id
          warnings["content_item_blocking_publish"] = "There is an item of content that prevents this draft from being published"
        end

        warnings
      end
    end
  end
end
