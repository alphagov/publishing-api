# frozen_string_literal: true

class PublishingApiSchema < GraphQL::Schema
  use GraphQL::Dataloader
  query(Types::QueryType)
end
