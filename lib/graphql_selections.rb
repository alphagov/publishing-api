class GraphqlSelections
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
    database_selections = new(editions: edition_fields & Edition.column_names.map(&:to_sym))

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
