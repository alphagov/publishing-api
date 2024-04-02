# frozen_string_literal: true

module Types
  class FeaturedDocumentType < Types::BaseObject
    description "A featured document"

    field :href, String
    field :image, ImageType
    field :summary, String
    field :title, String
  end
end
