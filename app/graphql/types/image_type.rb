# frozen_string_literal: true

module Types
  class ImageType < Types::BaseObject
    description "An image"

    field :alt_text, String
    field :url, String
  end
end
