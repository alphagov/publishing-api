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
      Link
        .joins(:link_set)
        .joins("INNER JOIN documents ON documents.content_id = link_sets.content_id")
        .joins("INNER JOIN editions ON editions.document_id = documents.id")
        .where("editions.id": edition_ids)
        .order("editions.id", :link_type, :position)
        .pluck("editions.id", :link_type, :target_content_id)
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
