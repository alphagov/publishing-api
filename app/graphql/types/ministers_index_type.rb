# frozen_string_literal: true

module Types
  class MinistersIndexType < Types::EditionType
    description "Ministers index page"
    field :cabinet_ministers, [PersonType]

    def cabinet_ministers
      link_set_links_from(link_types: %w[ordered_cabinet_ministers]).map do |link|
        Queries::GetEditionForContentStore.call(link[:target_content_id], "en")
      end
    end
  end
end
