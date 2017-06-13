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

        resolve_text_html(presented_edition)
      end

      def resolve_text_html(presented_edition)
        resolver = ContentTypeResolver.new("text/html")
        presented_edition[:details] = resolver.resolve(presented_edition[:details])
        presented_edition[:description] = resolver.resolve(presented_edition[:description])
        presented_edition
      end
    end
  end
end
