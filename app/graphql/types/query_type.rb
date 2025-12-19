# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :with_drafts, Boolean, required: false, default_value: false
    end

    def edition(base_path:, with_drafts:)
      content_stores = if with_drafts
                         %i[draft live]
                       else
                         %i[live]
                       end

      edition = Edition
        .includes(:document, :unpublishing)
        .where(base_path:, content_store: content_stores)
        .order(
          Arel.sql(
            <<~SQL,
              CASE editions.content_store
                WHEN 'draft' THEN 0
                WHEN 'live' THEN 1
                ELSE 2
              END
            SQL
          ),
        )
        .first

      return unless edition

      if edition.unpublishing && !edition.unpublishing.withdrawal?
        unpublishing_data = case edition.unpublishing.type
                            when "gone"
                              Presenters::GonePresenter.from_edition(edition).for_graphql
                            when "redirect"
                              Presenters::RedirectPresenter.from_unpublished_edition(edition).for_graphql
                            when "vanish"
                              Presenters::VanishPresenter.from_edition(edition).for_graphql
                            end

        raise GraphQL::ExecutionError.new("Edition has been unpublished", extensions: unpublishing_data)
      end

      context[:root_edition] = edition

      edition
    end
  end
end
