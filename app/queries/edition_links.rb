module Queries
  class EditionLinks
    def self.from(content_id,
      locale:,
      with_drafts:,
      allowed_link_types: nil)
      self.new(
        content_id: content_id,
        mode: :from,
        locale: locale,
        with_drafts: with_drafts,
        allowed_link_types: allowed_link_types,
      ).call
    end

    def self.to(content_id,
      locale:,
      with_drafts:,
      allowed_link_types: nil)
      self.new(
        content_id: content_id,
        mode: :to,
        locale: locale,
        with_drafts: with_drafts,
        allowed_link_types: allowed_link_types,
      ).call
    end

    def call
      return {} if allowed_link_types && allowed_link_types.empty?

      group_results(links_results)
    end

  private

    attr_reader :content_id, :mode, :locale, :with_drafts, :allowed_link_types

    def initialize(
      content_id:,
      mode:,
      locale:,
      with_drafts:,
      allowed_link_types:
    )
      @content_id = content_id
      @mode = mode
      @locale = locale
      @with_drafts = with_drafts
      @allowed_link_types = allowed_link_types
    end

    def links_results
      query = Link.left_joins(edition: :document)
      where(query)
        .order(link_type: :asc, position: :asc)
        .pluck(:link_type, link_field, "documents.locale", "editions.id")
    end

    def link_field
      mode == :from ? :target_content_id : "documents.content_id"
    end

    def where(query)
      condition = if mode == :from
                    { "documents.content_id": content_id }
                  else
                    { target_content_id: content_id }
                  end
      condition[:"documents.locale"] = locale if locale
      condition[:link_type] = allowed_link_types if allowed_link_types
      query.where(condition).where(draft_condition)
    end

    def draft_condition
      return { editions: { content_store: "live" } } unless with_drafts

      <<-SQL.strip_heredoc
        CASE WHEN EXISTS (
            SELECT 1 FROM editions AS e
            WHERE content_store = 'draft'
            AND e.document_id = documents.id
          )
          THEN editions.content_store = 'draft'
          ELSE editions.content_store = 'live'
        END
      SQL
    end

    def group_results(results)
      results
        .group_by(&:first)
        .each_with_object({}) do |(type, values), memo|
          hashes = values.map { |v| result_hash(v) }
          memo[type.to_sym] = hashes
        end
    end

    def result_hash(row)
      {
        content_id: row[1],
        locale: row[2],
        edition_id: row[3],
      }
    end
  end
end
