module Presenters
  module Queries
    class LinkSetPresenter
      def self.present(link_set)
        lock_version = LockVersion.find_by(target: link_set)
        new(link_set, lock_version).present
      end

      def initialize(link_set, lock_version = nil)
        self.link_set = link_set
        self.lock_version = lock_version
      end

      def present
        base = {
          content_id: link_set.content_id,
          links: links,
        }

        if lock_version
          base.merge(version: lock_version.number)
        else
          base
        end
      end

      def links
        # This method presents LinkSet#links as a hash.
        # Where keys are link types and their values are arrays of target content ids.
        # ie:
        # {
        #   related: [ UUID, UUID ],
        #   organisations: [ UUID ],
        # }

        link_set.links.map.with_object({}) do |link, hash|
          type = link.link_type.to_sym

          hash[type] ||= []
          hash[type] << link.target_content_id
        end
      end

    private

      attr_accessor :link_set, :lock_version
    end
  end
end
