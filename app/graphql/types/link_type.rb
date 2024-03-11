# frozen_string_literal: true

module Types
  class LinkType < Types::BaseObject
    description "A link"
    field :target_content_id, String
    field :link_type, String
  end
end
