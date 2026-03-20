Rails.application.config.permit_graphql_draft_content_access = ActiveModel::Type::Boolean
  .new
  .cast(ENV.fetch("GRAPHQL_DRAFT_CONTENT", false))
