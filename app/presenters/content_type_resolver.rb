module Presenters
  class ContentTypeResolver
    def initialize(content_type)
      self.content_type = content_type
    end

    def resolve(object)
      if object.is_a?(Hash)
        resolve_hash(object)
      elsif object.is_a?(Array)
        resolve_array(object)
      else
        object
      end
    end

    private

    def resolve_hash(hash)
      hash.inject({}) do |hash, (key, value)|
        hash.merge(key => resolve(value))
      end
    end

    def resolve_array(array)
      if has_content_types?(array)
        extract_content(array)
      else
        array.map { |e| resolve(e) }
      end
    end

    def has_content_types?(array)
      return false unless array.all? { |v| v.is_a?(Hash) }

      hash_keys = array.flat_map(&:keys).map(&:to_sym)
      hash_keys.include?(:content_type)
    end

    def extract_content(array)
      array = array.map(&:symbolize_keys)
      array.detect { |h| h[:content_type] == content_type }[:content]
    end

    attr_accessor :content_type
  end
end
