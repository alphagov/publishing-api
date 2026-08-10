module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(locale:, with_drafts: false)
      @query = Queries::LinkedToEditions.new(locale:, with_drafts:)
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      @query.call(editions_and_link_types).values
    end
  end
end
