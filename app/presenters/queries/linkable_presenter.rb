module Presenters
  module Queries
    class LinkablePresenter
      def self.present(linkable)
        self.new(
          content_item: linkable.content_item,
          linkable: linkable,
        ).present
      end

      def initialize(content_item:, linkable:)
        @content_item = content_item
        @linkable = linkable
      end

      def present
        {
          title: content_item.title,
          content_id: content_item.content_id,
          publication_state: publication_state,
          base_path: linkable.base_path,
          internal_name: internal_name,
        }
      end

    private

      attr_reader :content_item, :linkable

      def internal_name
        content_item.details[:internal_name] || content_item.title
      end

      def publication_state
        case linkable.state
        when "published"
          "live"
        else
          linkable.state
        end
      end
    end
  end
end
