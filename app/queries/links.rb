module Queries
  class Links
    ##
    # For a given content_id of a LinkSet return the content_ids of links
    # that are targetted. These are grouped by link type.
    #
    # > pp Queries::Links.from(LinkSet.last.content_id)
    # => {:organisations=> [
    #      {:content_id=>"7cd6bf12-bbe9-4118-8523-f927b0442156",
    #       :has_own_links=>nil,
    #       :is_linked_to=>nil}]}
    #
    # an array of allowed_link_types can be provided to restrict the results to
    # a subset of link types
    # parent_content_ids is an array of content_ids that is used to reject
    # cyclic links
    #
    # next_allowed_link_types_from and next_allowed_link_types_to can be used to
    # check whether the links that are found in these results have links of
    # their own (which is used to optimise the amount of queries we make in
    # calculating an expanded link_set.
    # These are provided as hashes with the next links that can be allowed as
    # an array. eg { taxons: [:parent_taxons] } - which means that for
    # link_types of `taxons` they can only have children of `parent_taxons`
    #
    # next_allowed_link_types_from checks whether there are links defined for
    # a content_id to links - considered own_links
    # next_allowed_link_types_to checks where there are links that target this
    # links - considered as is_linked_to
    #
    # The response is a hash with keys of link type and an array of links
    # matching that link_type. These links are represented with a hash of:
    #
    # content_id: the content_id of the link
    # has_own_links: true/false if it was determined there were/were not links
    # from the content_id, nil if it wasn't checked.
    # is_linked_to: true/false if it was determined there were/were not links
    # to the content_id, nil if it wasn't checked.
    def self.from(content_id,
      allowed_link_types: nil,
      parent_content_ids: [],
      next_allowed_link_types_from: nil,
      next_allowed_link_types_to: nil)
      self.new(
        content_id: content_id,
        mode: :from,
        allowed_link_types: allowed_link_types,
        parent_content_ids: parent_content_ids,
        next_allowed_link_types_from: next_allowed_link_types_from,
        next_allowed_link_types_to: next_allowed_link_types_to,
      ).call
    end

    ##
    # For a given content_id in a link return the content_ids of LinkSets which
    # have links to this content_id
    #
    # See #from method for further description
    def self.to(content_id,
      allowed_link_types: nil,
      parent_content_ids: [],
      next_allowed_link_types_from: nil,
      next_allowed_link_types_to: nil)
      self.new(
        content_id: content_id,
        mode: :to,
        allowed_link_types: allowed_link_types,
        parent_content_ids: parent_content_ids,
        next_allowed_link_types_from: next_allowed_link_types_from,
        next_allowed_link_types_to: next_allowed_link_types_to,
      ).call
    end

    def call
      return {} if allowed_link_types && allowed_link_types.empty?

      group_results(links_results)
    end

  private

    attr_reader :content_id, :mode, :allowed_link_types, :parent_content_ids,
                :next_allowed_link_types_from, :next_allowed_link_types_to

    def initialize(
      content_id:,
      mode:,
      allowed_link_types: nil,
      parent_content_ids: [],
      next_allowed_link_types_from: nil,
      next_allowed_link_types_to: nil
    )
      @content_id = content_id
      @mode = mode
      @allowed_link_types = allowed_link_types
      @parent_content_ids = parent_content_ids
      @next_allowed_link_types_from = next_allowed_link_types_from
      @next_allowed_link_types_to = next_allowed_link_types_to
    end

    def links_results
      Link
        .joins(:link_set)
        .where(where)
        .where.not(where_not)
        .order(link_type: :asc, position: :asc)
        .pluck(*fields)
    end

    def where
      if mode == :from
        where = { "link_sets.content_id": content_id }
      else
        where = { "links.target_content_id": content_id }
      end
      where[:link_type] = allowed_link_types if allowed_link_types
      where
    end

    def where_not
      { link_content_id_field => parent_content_ids }
    end

    def fields
      base_fields = [:link_type, link_content_id_field]
      base_fields << has_own_links_field if check_for_from_children?
      base_fields << is_linked_to_field if check_for_to_children?
      base_fields
    end

    def link_content_id_field
      mode == :from ? "links.target_content_id" : "link_sets.content_id"
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
        has_own_links: has_own_links_result(row),
        is_linked_to: is_linked_to_result(row),
      }
    end

    def has_own_links_result(row)
      return false unless could_have_from_children?

      check_for_from_children? ? row[2] : nil
    end

    def is_linked_to_result(row)
      return false unless could_have_to_children?

      check_for_from_children? ? row[3] : row[2]
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
      children_field(
        %{
          nested_link_sets.content_id = #{link_content_id_field}
          #{and_not_parent('nested_links.target_content_id')}
          AND (#{allowed_links_condition(next_allowed_link_types_from)})
        },
      )
    end

    def is_linked_to_field
      children_field(
        %{
          nested_links.target_content_id = #{link_content_id_field}
          #{and_not_parent('nested_link_sets.content_id')}
          AND (#{allowed_links_condition(next_allowed_link_types_to)})
        },
      )
    end

    def children_field(where)
      Arel.sql(%{
        EXISTS(
          SELECT nested_links.id
          FROM links AS nested_links
          INNER JOIN link_sets AS nested_link_sets
          ON nested_link_sets.id = nested_links.link_set_id
          WHERE #{where}
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
