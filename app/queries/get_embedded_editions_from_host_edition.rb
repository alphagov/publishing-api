module Queries
  class GetEmbeddedEditionsFromHostEdition
    def self.call(edition:)
      Edition.with_document
                              .where(
                                documents: {
                                  content_id: edition.links.where(link_type:).pluck(:target_content_id),
                                },
                              )
                              .where(Edition.arel_table[:state].eq("published"))
                              .index_by(&:content_id)
    end

    def self.link_type
      "embed"
    end
  end
end
