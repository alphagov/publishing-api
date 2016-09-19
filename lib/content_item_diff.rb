require 'hashdiff'

class ContentItemDiff
  attr_reader :current_content_item, :version

  def initialize(current_content_item, version: nil)
    @current_content_item = current_content_item
    @version = version
  end

  def create
    return unless diff.present?
    ContentHistory.create!(diff: { diff: diff }.to_json, version: current_user_version, previous_version: previous_user_version, content_id: current_content_item.content_id)
  end

  def diff
    return [] if current_user_version < 2
    HashDiff.diff(presented_item(old_id), presented_item(current_content_item.id))
  end

  def old_id
    @old_id ||= UserFacingVersion.filter(ContentItem.where(content_id: current_content_item.content_id), number: previous_user_version).pluck(:id).first
  end

  def previous_user_version
    current_user_version - 1
  end

  def current_user_version
    version || ContentItemFilter.user_facing_version(current_content_item).number
  end

  def presented_item(id)
    Presenters::DownstreamPresenter.present(web_item(id), state_fallback_order: :published).deep_stringify_keys
  end

  def web_item(id)
    Queries::GetWebContentItems.find(id)
  end
end
