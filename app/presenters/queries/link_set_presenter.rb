module Presenters
  module Queries
    class LinkSetPresenter
      def self.present(link_set)
        new(link_set).present
      end

      def initialize(link_set)
        self.link_set = link_set
      end

      def present
        {
          content_id: link_set.content_id,
          links: links,
          version: link_set.stale_lock_version,
        }
      end

      def links
        # This method presents LinkSet#links as a hash.
        # Where keys are link types and their values are arrays of target content ids.
        # ie:
        # {
        #   related: [ UUID, UUID ],
        #   organisations: [ UUID ],
        # }

        @links ||= link_set.links.pluck(:link_type, :target_content_id).map.with_object({}) do |link, hash|
          type = link[0].to_sym

          hash[type] ||= []
          hash[type] << link[1]
        end
      end

    private

      attr_accessor :link_set, :lock_version
    end
  end
end
