module Presenters
  module Queries
    class LinkablePresenter
      def self.present(content_id, state, title, base_path, updated_at, created_at, internal_name)
        {
          title: title,
          content_id: content_id,
          publication_state: state,
          base_path: base_path,
          updated_at: updated_at,
          created_at: created_at,
          internal_name: internal_name || title,
        }
      end
    end
  end
end
