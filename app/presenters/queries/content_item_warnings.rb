module Presenters
  module Queries
    module ContentItemWarnings
      def self.call(content_id, state, base_path, document_type)
        return unless state == "draft"

        blocking_content_item_id = ::Queries::LiveEditionBlockingDraftEdition.call(
          content_id,
          base_path,
          document_type,
        )

        warnings = {}

        if blocking_content_item_id
          warnings["content_item_blocking_publish"] = "There is an item of content that prevents this draft from being published"
        end

        warnings
      end
    end
  end
end
