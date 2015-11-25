module Presenters
  module Queries
    class LinkSetPresenter
      def self.present(link_set)
        version = Version.find_by(target: link_set)
        new(link_set, version).present
      end

      def initialize(link_set, version = nil)
        self.link_set = link_set
        self.version = version
      end

      def present
        base = link_set.as_json.symbolize_keys

        if version
          base.merge(version: version.number)
        else
          base
        end
      end

      def links
        present[:links]
      end

    private

      attr_accessor :link_set, :version
    end
  end
end
