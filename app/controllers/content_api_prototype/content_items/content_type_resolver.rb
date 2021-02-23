# taken from https://github.com/alphagov/content-store/blob/master/app/presenters/content_type_resolver.rb
module ContentApiPrototype
  module ContentItems
    class ContentTypeResolver
      def initialize(content_type)
        self.content_type = content_type
      end

      def resolve(object)
        case object
        when Hash
          resolve_hash(object)
        when Array
          resolve_array(object)
        else
          object
        end
      end

    private

      def resolve_hash(hash)
        hash.inject({}) do |memo, (key, value)|
          memo.merge(key => resolve(value))
        end
      end

      def resolve_array(array)
        if array.all? { |v| v.is_a?(Hash) }
          array = array.map(&:symbolize_keys)
          content_for_type = extract_content(array)
        end

        if content_for_type
          content_for_type[:content]
        else
          array.map { |e| resolve(e) }
        end
      end

      def extract_content(array)
        array.detect { |h| h[:content_type] == content_type && h[:content] }
      end

      attr_accessor :content_type
    end
  end
end
