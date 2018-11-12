module Queries
  class LinksForEditionIds
    attr_reader :edition_ids

    def initialize(edition_ids)
      @edition_ids = edition_ids
    end

    def merged_links
      @merged_links ||= begin
                          keys = (edition_links.keys + link_set_links.keys).uniq
                          keys.each_with_object(Hash.new({})) do |id, memo|
                            memo[id] = link_set_links[id].merge(edition_links[id])
                          end
                        end
    end

    def edition_links
      @edition_links ||= group_by_edition_id_and_link_type(query_edition_links)
    end

    def link_set_links
      @link_set_links ||= group_by_edition_id_and_link_type(query_link_set_links)
    end

  private

    def query_edition_links
      Link
        .where(edition_id: edition_ids)
        .order(:edition_id, :link_type, :position)
        .pluck(:edition_id, :link_type, :target_content_id)
    end

    def query_link_set_links
      # This may seem strange to be 3 queries but it was 10-100x more performant
      # than a single one which seemed to struggle on joining link_sets.content_id
      edition_id_content_id = Edition.with_document.where(id: edition_ids).pluck(:id, :content_id).to_h
      content_ids = edition_id_content_id.map(&:last)
      content_id_link_set_id = LinkSet.where(content_id: content_ids).pluck(:content_id, :id).to_h
      links = Link
                .where(link_set_id: content_id_link_set_id.map(&:last))
                .order(:link_set_id, :link_type, :position)
                .pluck(:link_set_id, :link_type, :target_content_id)
                .group_by(&:first)

      edition_id_content_id.flat_map do |(edition_id, content_id)|
        link_set_id = content_id_link_set_id[content_id]
        links.fetch(link_set_id, []).map do |(_, link_type, target_content_id)|
          [edition_id, link_type, target_content_id]
        end
      end
    end

    def group_by_edition_id_and_link_type(links)
      hash = links.group_by(&:first)
      hash.default = {}
      hash.transform_values! do |value|
        value.each_with_object({}) do |(_, type, content_id), memo|
          memo[type] ||= []
          memo[type] << content_id
        end
      end
    end
  end
end
