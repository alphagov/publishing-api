module Queries
  class Links
    ##
    # For a given content_id of a LinkSet return the content_ids of links
    # that are targeted. These are grouped by link type.
    #
    # > pp Queries::Links.from(LinkSet.last.content_id)
    # => {:organisations=>[{:content_id=>"7cd6bf12-bbe9-4118-8523-f927b0442156"}]}
    #
    # an array of allowed_link_types can be provided to restrict the results to
    # a subset of link types.
    def self.from(content_id, allowed_link_types: nil)
      new(content_id:, mode: :from, allowed_link_types:).call
    end

    ##
    # For a given content_id in a link return the content_ids of LinkSets which
    # have links to this content_id, grouped by link type.
    #
    # See #from for further description.
    def self.to(content_id, allowed_link_types: nil)
      new(content_id:, mode: :to, allowed_link_types:).call
    end

    def call
      return {} if allowed_link_types && allowed_link_types.empty?

      group_results(links_results)
    end

  private

    attr_reader :content_id, :mode, :allowed_link_types

    def initialize(content_id:, mode:, allowed_link_types: nil)
      @content_id = content_id
      @mode = mode
      @allowed_link_types = allowed_link_types
    end

    def links_results
      Link
        .link_set_links
        .where(where)
        .order(link_type: :asc, position: :asc, id: :desc)
        .pluck(:link_type, link_content_id_field)
    end

    def where
      where = if mode == :from
                { "links.link_set_content_id": content_id }
              else
                { "links.target_content_id": content_id }
              end
      where[:link_type] = allowed_link_types if allowed_link_types
      where
    end

    def link_content_id_field
      mode == :from ? "links.target_content_id" : "links.link_set_content_id"
    end

    def group_results(results)
      results
        .group_by(&:first)
        .each_with_object({}) do |(type, values), memo|
          memo[type.to_sym] = values.map { |row| { content_id: row[1] } }
        end
    end
  end
end
