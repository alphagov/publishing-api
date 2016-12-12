class ContentItemFilter
  def initialize(scope: ContentItem.all)
    self.scope = scope
  end

  def self.similar_to(content_item, params = {})
    params = params.dup

    params[:locale] = content_item.locale unless params.has_key?(:locale)
    params[:base_path] = content_item.try(:base_path) unless params.has_key?(:base_path)
    params[:state] = content_item.state unless params.has_key?(:state)
    params[:user_version] = content_item.user_facing_version unless params.has_key?(:user_version)

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

protected

  attr_accessor :scope
end
