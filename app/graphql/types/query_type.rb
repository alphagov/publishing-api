# frozen_string_literal: true

module Types
  ALL_EDITION_COLUMNS = Set.new(%i[
    analytics_identifier
    auth_bypass_ids
    base_path
    content_store
    created_at
    description
    details
    document_id
    document_type
    first_published_at
    id
    last_edited_at
    last_edited_by_editor_id
    major_published_at
    phase
    public_updated_at
    published_at
    publishing_api_first_published_at
    publishing_api_last_edited_at
    publishing_app
    publishing_request_id
    redirects
    rendering_app
    routes
    schema_name
    state
    title
    update_type
    updated_at
    user_facing_version
  ]).freeze

  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :content_store, String, required: false, default_value: "live"

      extras [:lookahead]
    end

    def edition(base_path:, content_store:, lookahead:)
      all_selections = lookahead.selections.map(&:name)

      links_are_selected = all_selections.delete(:links)

      attributes = all_selections
      attributes << "id"
      attributes << "document_type"
      # id for edition link queries,
      # document_type for EditionTypeOrSubtype

      if links_are_selected
        attributes << "content_store"
        attributes << "documents.content_id"
        # content_store for BaseObject#links_field #reverse_links_field
        # documents.content_id for getting LinkSet Links

        Edition
          .left_outer_joins(:document)
          .select(attributes).where(content_store:).find_by(base_path:)
      else
        Edition.select(attributes).where(content_store:).find_by(base_path:)
      end
    end
  end
end
