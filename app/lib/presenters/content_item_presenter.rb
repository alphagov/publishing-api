Presenters = Module.new unless defined?(Presenters)

class Presenters::ContentItemPresenter
  attr_reader :content_item

  def initialize(content_item)
    @content_item = content_item
  end

  def present
    raw_json.except("metadata", "id").merge(raw_json['metadata']).deep_symbolize_keys
  end

  def raw_json
    content_item.as_json
  end
end
