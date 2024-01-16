module Queries
  class EditionLinks
    def self.from(content_id,
                  locale:,
                  with_drafts:,
                  allowed_link_types: nil,
                  parent_content_ids: [],
                  next_allowed_link_types_from: nil,
                  next_allowed_link_types_to: nil)
      new(
        content_id:,
        mode: :from,
        locale:,
        with_drafts:,
        allowed_link_types:,
        parent_content_ids:,
        next_allowed_link_types_from:,
        next_allowed_link_types_to:,
      ).call
    end

    def self.to(content_id,
                locale:,
                with_drafts:,
                allowed_link_types: nil,
                parent_content_ids: [],
                next_allowed_link_types_from: nil,
                next_allowed_link_types_to: nil)
      new(
        content_id:,
        mode: :to,
        locale:,
        with_drafts:,
        allowed_link_types:,
        parent_content_ids:,
        next_allowed_link_types_from:,
        next_allowed_link_types_to:,
      ).call
    end

    def call
      return {} if allowed_link_types && allowed_link_types.empty?

      group_results(links_results)
    end

  private

    attr_reader :content_id,
                :mode,
                :locale,
                :with_drafts,
                :allowed_link_types,
                :parent_content_ids,
                :next_allowed_link_types_from,
                :next_allowed_link_types_to

    def initialize(
      content_id:,
      mode:,
      locale:,
      with_drafts:,
      allowed_link_types:,
      parent_content_ids: [],
      next_allowed_link_types_from: nil,
      next_allowed_link_types_to: nil
    )
      @content_id = content_id
      @mode = mode
      @locale = locale
      @with_drafts = with_drafts
      @allowed_link_types = allowed_link_types
      @parent_content_ids = parent_content_ids
      @next_allowed_link_types_from = next_allowed_link_types_from
      @next_allowed_link_types_to = next_allowed_link_types_to
    end

    def links_results
      condition = {}
      # condition[:"documents.locale"] = locale if locale
      condition[:link_type] = allowed_link_types if allowed_link_types

      if mode == :from
        puts "from"
        Link
          .left_joins(edition: :document)
          .left_joins(:link_set)
          .where("documents.content_id": content_id)
          .or(Link.where("link_sets.content_id": content_id))
          .where(condition)
          .where(draft_condition)
          .order(link_type: :asc, position: :asc)
          .pluck(*fields)
      else
        puts "to"
        links = Link
          .left_joins(edition: :document)
          .left_joins(:link_set)
          .where("links.target_content_id": content_id)
          .where(condition)
          .where(draft_condition)
          .order(link_type: :asc, position: :asc)
          .pluck(*fields)
        puts content_id
        puts links.inspect
        puts Link.left_joins(edition: :document).left_joins(:link_set).where("links.target_content_id": content_id).where(condition).inspect
        links
      end
    end

    def fields
      base_fields = [
        :link_type,
        mode == :from ? :target_content_id : "documents.content_id",
        mode == :from ? :target_content_id : "link_sets.content_id",
        "documents.locale",
        "editions.id",
      ]
      base_fields << has_own_links_field if check_for_from_children?
      base_fields << is_linked_to_field if check_for_to_children?
      base_fields
    end

    def draft_condition
      return { editions: { content_store: "live" } } unless with_drafts
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
        content_id: row[1] || row[2],
        locale: row[3],
        edition_id: row[4],
        has_own_links: has_own_links_result(row),
        is_linked_to: is_linked_to_result(row),
      }
    end

    def has_own_links_result(row)
      return false unless could_have_from_children?

      check_for_from_children? ? row[5] : nil
    end

    def is_linked_to_result(row)
      return false unless could_have_to_children?

      check_for_from_children? ? row[6] : row[5]
    end

    def check_for_from_children?
      next_allowed_link_types_from && next_allowed_link_types_from.present?
    end

    def check_for_to_children?
      next_allowed_link_types_to && next_allowed_link_types_to.present?
    end

    def could_have_from_children?
      next_allowed_link_types_from.nil? || next_allowed_link_types_from.present?
    end

    def could_have_to_children?
      next_allowed_link_types_to.nil? || next_allowed_link_types_to.present?
    end

    def has_own_links_field
      if mode == :from
        Arel.sql(%{
          EXISTS(
            SELECT nested_links.id
            FROM links AS nested_links
            INNER JOIN link_sets AS nested_link_sets
            ON nested_link_sets.id = nested_links.link_set_id
            WHERE nested_link_sets.content_id = links.target_content_id
            #{and_not_parent('nested_links.target_content_id')}
            AND (#{allowed_links_condition(next_allowed_link_types_from)})
            LIMIT 1
          ) OR EXISTS(
            SELECT nested_links.id
            FROM links AS nested_links
            INNER JOIN documents AS nested_documents
            ON nested_documents.content_id = nested_links.target_content_id
            WHERE nested_documents.content_id = links.target_content_id
            #{and_not_parent('nested_links.target_content_id')}
            AND (#{allowed_links_condition(next_allowed_link_types_from)})
            LIMIT 1
          )
      })
      else
        Arel.sql(%{
            EXISTS(
              SELECT nested_links.id
              FROM links AS nested_links
              INNER JOIN link_sets AS nested_link_sets
              ON nested_link_sets.id = nested_links.link_set_id
              WHERE nested_links.target_content_id = link_sets.content_id
              #{and_not_parent('nested_links.target_content_id')}
              AND (#{allowed_links_condition(next_allowed_link_types_from)})
              LIMIT 1
            ) OR EXISTS(
              SELECT nested_links.id
              FROM links AS nested_links
              INNER JOIN documents AS nested_documents
              ON nested_documents.content_id = nested_links.target_content_id
              WHERE nested_links.target_content_id = documents.content_id
              #{and_not_parent('nested_links.target_content_id')}
              AND (#{allowed_links_condition(next_allowed_link_types_from)})
              LIMIT 1
            )
        })
      end
    end

    def is_linked_to_field
      query = if mode == :from
                "nested_links.target_content_id = links.target_content_id"
              else
                "(nested_links.target_content_id = link_sets.content_id OR nested_links.target_content_id = documents.content_id)"
              end

      Arel.sql(%{
        EXISTS(
          SELECT nested_links.id
          FROM links AS nested_links
          LEFT JOIN link_sets AS nested_link_sets
          ON nested_link_sets.id = nested_links.link_set_id
          LEFT JOIN documents AS nested_documents
          ON nested_documents.content_id = nested_links.target_content_id
          WHERE #{query}
          #{and_not_parent('nested_link_sets.content_id')}
          AND (#{allowed_links_condition(next_allowed_link_types_to)})
          LIMIT 1
        )
      })
    end

    def and_not_parent(field)
      return if parent_content_ids.empty?

      quoted = parent_content_ids.map { |c_id| quote(c_id) }

      "AND #{field} NOT IN (#{quoted.join(', ')})"
    end

    def allowed_links_condition(allowed_links)
      each_link_type = allowed_links.map do |(link_type, next_links)|
        raise "Empty links for #{link_type} on #{content_id}" if next_links.empty?

        quoted_next_links = next_links.map { |n| quote(n) }

        "(links.link_type = #{quote(link_type)} AND nested_links.link_type IN (#{quoted_next_links.join(', ')}))"
      end

      each_link_type.join(" OR ")
    end

    def quote(field)
      ActiveRecord::Base.connection.quote(field)
    end
  end
end
