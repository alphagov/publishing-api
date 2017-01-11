require 'hashdiff'

class ContentItemDiff
  attr_reader :current_content_item, :version
  NullItem = Struct.new(:id)

  def initialize(current_content_item, version: nil)
    @current_content_item = current_content_item
    @version = version
  end

  def field_diff
    diff.map {|_,field,_| field.to_sym }
  end

private

  def diff
    HashDiff.best_diff(presented_item(old_item.id),
                       presented_item(current_content_item.id))
  end

  def old_item
    ContentItem.find_by(content_id: current_content_item.content_id,
                        user_facing_version: previous_user_version) ||
                        NullItem.new
  end

  def previous_user_version
    current_user_version - 1
  end

  def current_user_version
    version || current_content_item.user_facing_version
  end

  def presented_item(id)
    Presenters::DownstreamPresenter.present(web_item(id),
                                            state_fallback_order: :published
                                           ).deep_stringify_keys
  end

  def web_item(id)
    Queries::GetWebContentItems.find(id)
  end
end
