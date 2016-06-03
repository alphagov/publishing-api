module Presenters
  module Queries
    class LinkablePresenter
      def self.present(content_id, state, title, base_path, internal_name)
        {
          title: title,
          content_id: content_id,
          publication_state: publication_state(state),
          base_path: base_path,
          internal_name: internal_name || title,
        }
      end

      def self.publication_state(state)
        case state
        when "published"
          "live"
        else
          state
        end
      end
    end
  end
end
