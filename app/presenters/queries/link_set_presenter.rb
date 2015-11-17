module Presenters
  module Queries
    class LinkSetPresenter
      def self.present(link_set)
        version = Version.find_by(target: link_set)
        new(link_set, version).present
      end

      def initialize(link_set, version)
        self.link_set = link_set
        self.version = version
      end

      def present
        link_set.as_json
          .symbolize_keys
          .merge({
            version: version.number,
            links: link_set.hashed_links,
          })
      end

    private

      attr_accessor :link_set, :version
    end
  end
end
