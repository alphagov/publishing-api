class Presenters::ContentTypeResolver
  class NotFoundError < RuntimeError; end

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
    contains_content_hashes = array.any? { |h| h[:content_type] && h[:content] }
    result = array.detect { |h| h[:content_type] == content_type && h[:content] }
    raise NotFoundError, "Expected to find #{content_type} in #{array.inspect}" if contains_content_hashes && result.nil?

    result
  end

  attr_accessor :content_type
end
