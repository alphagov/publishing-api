# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :with_drafts, Boolean, required: false, default_value: false
    end

    def edition(base_path:, with_drafts:)
      all_states = if with_drafts
                     %i[draft published unpublished]
                   else
                     %i[published unpublished]
                   end

      edition = Edition
        .includes(:document, :unpublishing)
        .where(base_path:, state: all_states)
        .order(
          Arel.sql(
            <<~SQL,
              CASE editions.state
                WHEN 'draft' THEN 0
                WHEN 'published' THEN 1
                WHEN 'unpublished' THEN 2
                ELSE 3
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
