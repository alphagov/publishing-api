class ContentItemFilter
  def initialize(scope: ContentItem.all)
    self.scope = scope
  end

  def self.similar_to(content_item, params = {})
    params = params.dup

    params[:locale] = translation(content_item).locale unless params.has_key?(:locale)
    params[:base_path] = location(content_item).try(:base_path) unless params.has_key?(:base_path)
    params[:state] = state(content_item).name unless params.has_key?(:state)
    params[:user_version] = user_facing_version(content_item).number unless params.has_key?(:user_version)

    scope = ContentItem.where(content_id: content_item.content_id)

    new(scope: scope).filter(params)
  end

  def self.filter(**args)
    self.new.filter(**args)
  end

  def filter(locale: nil, base_path: nil, state: nil, user_version: nil)
    scope = self.scope
    scope = scope.where(locale: locale) if locale
    scope = scope.where(base_path: base_path) if base_path
    scope = scope.where(state: state) if state
    scope = scope.where(user_facing_version: user_version) if user_version
    scope
  end

  def self.translation(content_item)
    Translation.find_by!(content_item: content_item)
  end

  def self.location(content_item)
    Location.find_by(content_item: content_item)
  end

  def self.state(content_item)
    State.find_by!(content_item: content_item)
  end

  def self.user_facing_version(content_item)
    UserFacingVersion.find_by!(content_item: content_item)
  end

protected

  attr_accessor :scope
end
