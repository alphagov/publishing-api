module Queries
  module GetBulkLinks
    def self.call(content_ids = [])
      content_ids.each_with_object({}) do |content_id, hsh|
        hsh[content_id] = link_set(content_id)
      end
    end

    def self.link_set(content_id)
      link_set = LinkSet.find_by(content_id: content_id)
      return { links: {}, version: 0 } unless link_set

      Presenters::Queries::LinkSetPresenter
        .present(link_set)
        .slice(:links, :version)
    end
  end
end
