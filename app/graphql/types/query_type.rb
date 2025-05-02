# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :content_store, String, required: false, default_value: "live"
    end

    def edition(base_path:, content_store:)
      edition = Edition
        .includes(:unpublishing)
        .where(content_store:)
        .find_by(base_path:)

      return unless edition

      if edition.unpublishing && !edition.unpublishing.withdrawal?
        unpublishing_data = case edition.unpublishing.type
                            when "gone"
                              Presenters::GonePresenter.from_edition(edition).for_graphql
                            when "vanish"
                              Presenters::VanishPresenter.from_edition(edition).for_graphql
                            end

        raise GraphQL::ExecutionError.new("Edition has been unpublished", extensions: unpublishing_data)
      end

      edition
    end
  end
end
