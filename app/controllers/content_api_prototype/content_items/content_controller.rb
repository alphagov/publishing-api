module ContentApiPrototype
  module ContentItems
    class ContentController < ApplicationController
      def by_base_path
        edition = Edition
          .where(base_path: base_path, content_store: "live")
          .order(user_facing_version: "DESC")
          .first!

        render json: present(edition)
      end

      def by_content_id
        edition = Edition
          .with_document
          .find_by!(
            documents: {
              content_id: path_params[:content_id],
              locale: path_params[:locale]
            },
            user_facing_version: path_params[:user_facing_version]
          )

        render json: present(edition)
      end

    private

      def present(edition)
        presented_edition = Presenters::EditionPresenter
          .new(edition, draft: edition.draft?)
          .for_content_store(0)

        presented_edition = resolve_text_html(presented_edition)

        inject_links(presented_edition, edition)
      end

      def resolve_text_html(presented_edition)
        resolver = ContentTypeResolver.new("text/html")
        presented_edition[:details] = resolver.resolve(presented_edition[:details])
        presented_edition[:description] = resolver.resolve(presented_edition[:description])
        presented_edition
      end

      def user_facing_version_for(edition, position)
        return edition.user_facing_version + 1 if position == :next
        return edition.user_facing_version - 1 if position == :prev

        raise "Invalid position, must be :next or :prev"
      end

      def sibling_edition(edition, position)
        version = user_facing_version_for(edition, position)
        edition.document.editions
          .where(user_facing_version: version, content_store: [nil, "live"])
          .first
      end

      def link_to_sibling(edition, position)
        other_edition = sibling_edition(edition, position)
        return unless other_edition

        "/content/#{other_edition.document.content_id}/#{other_edition.document.locale}/#{other_edition.user_facing_version}"
      end

      def inject_links(presented_edition, edition)
        presented_edition[:historical_links] = {
          next: link_to_sibling(edition, :next),
          prev: link_to_sibling(edition, :prev),
        }

        presented_edition
      end
    end
  end
end
