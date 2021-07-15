module Queries
  class GetBulkLinks
    def self.call(content_ids)
      new(content_ids).call
    end

    def initialize(content_ids)
      @content_ids = content_ids
    end

    def call
      content_ids.index_with { |content_id| link_set(content_id) }
    end

  private

    attr_reader :content_ids

    def link_set(content_id)
      link_set = link_sets[content_id]
      return { links: {}, version: 0 } unless link_set

      Presenters::Queries::LinkSetPresenter
        .present(link_set)
        .slice(:links, :version)
    end

    def link_sets
      @link_sets ||= LinkSet
          .includes(:links) # avoid an N+1 in the presenter class
          .where("content_id IN (?)", content_ids)
          .index_by(&:content_id) # reform the Relation into a hash, keyed by content_id
    end
  end
end
