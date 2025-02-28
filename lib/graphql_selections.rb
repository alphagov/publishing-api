class GraphqlSelections
  ALL_EDITION_COLUMNS = %i[
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
  ].freeze

  FIELDS_TO_COLUMNS = {
    content_id: [:documents, %i[content_id]],
    links: [:editions, %i[id content_store]],
    locale: [:documents, %i[locale]],
    web_url: [:editions, %i[base_path]],
  }.freeze

  ROOT_EDITION_FIELDS_TO_COLUMNS = {
    links: [:documents, %i[content_id locale]],
    withdrawn_notice: [
      :unpublishings,
      [
        "created_at AS unpublishing_created_at",
        "explanation AS unpublishing_explanation",
        "type AS unpublishing_type",
        "unpublished_at AS unpublishing_unpublished_at",
      ],
    ],
  }.freeze

  def initialize(tables_and_columns)
    @tables_and_columns = tables_and_columns
  end

  def self.with_edition_fields(edition_fields)
    database_selections = new(editions: ALL_EDITION_COLUMNS & edition_fields)

    FIELDS_TO_COLUMNS.slice(*edition_fields).each_value do |(table, columns)|
      database_selections.insert(table, columns)
    end

    database_selections
  end

  def self.with_root_edition_fields(edition_fields)
    database_selections = with_edition_fields(edition_fields)

    ROOT_EDITION_FIELDS_TO_COLUMNS.slice(*edition_fields).each_value do |(table, columns)|
      database_selections.insert(table, columns)
    end

    database_selections.insert(:editions, %i[document_type])

    database_selections
  end

  def merge(other)
    other.to_h.each do |table, columns|
      insert(table, columns)
    end
  end

  def insert(table, columns)
    @tables_and_columns[table] ||= []
    @tables_and_columns[table].push(*columns).uniq!
  end

  def selects_from_table?(table)
    @tables_and_columns[table].present?
  end

  def to_h
    @tables_and_columns.deep_dup
  end
end
