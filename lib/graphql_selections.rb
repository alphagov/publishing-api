class GraphqlSelections
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

  FIELDS_TO_COLUMNS = {
    content_id: [:documents, %i[content_id]],
    links: [:editions, %i[id content_store]],
    locale: [:documents, %i[locale]],
    web_url: [:editions, %i[base_path]],
  }.freeze

  def initialize(tables_and_columns)
    @tables_and_columns = tables_and_columns
      .each_with_object({}) do |(table, columns), hash|
        hash[table] = Set.new(columns)
      end
  end

  def self.with_edition_fields(edition_fields)
    database_selections = new(editions: ALL_EDITION_COLUMNS & edition_fields)

    FIELDS_TO_COLUMNS.slice(*edition_fields).values.each do |(table, columns)|
      database_selections.insert(table, columns)
    end

    database_selections
  end

  def merge(other)
    other.each do |table, columns|
      insert(table, columns)
    end
  end

  def insert(table, columns)
    @tables_and_columns[table] ||= Set.new
    @tables_and_columns[table].merge(columns)
  end

  def selects_from_table?(table)
    @tables_and_columns[table].present?
  end

  def to_select_args
    @tables_and_columns.transform_values(&:to_a)
  end

protected

  def each(&block)
    @tables_and_columns.each(&block)
  end
end
