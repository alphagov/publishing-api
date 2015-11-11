module Presenters
  module Queries
    class ContentItemPresenter
      def self.present(content_item)
        version = Version.find_by(target: content_item)
        new(content_item, version).present
      end

      def initialize(content_item, version)
        self.content_item = content_item
        self.version = version
      end

      def present
        content_item.as_json
          .symbolize_keys
          .merge(version: version.number)
      end

    private

      attr_accessor :content_item, :version
    end
  end
end
