class ContentItemFilter
  def initialize(scope: ContentItem.all)
    self.scope = scope
  end

  def self.similar_to(content_item, params = {})
    params = params.dup

    params[:locale] = translation(content_item).locale unless params.has_key?(:locale)
    params[:base_path] = location(content_item).base_path unless params.has_key?(:base_path)
    params[:state] = state(content_item).name unless params.has_key?(:state)
    params[:semver] = semantic_version(content_item).number unless params.has_key?(:semver)

    scope = ContentItem.where(content_id: content_item.content_id)

    new(scope: scope).filter(params)
  end

  def self.filter(**args)
    self.new.filter(**args)
  end

  def filter(locale: nil, base_path: nil, state: nil, semver: nil)
    scope = self.scope
    scope = Location.filter(scope, base_path: base_path) if base_path
    scope = Translation.filter(scope, locale: locale) if locale
    scope = State.filter(scope, name: state) if state
    scope = SemanticVersion.filter(scope, number: semver) if semver
    scope
  end

  def self.translation(content_item)
    Translation.find_by!(content_item: content_item)
  end

  def self.location(content_item)
    Location.find_by!(content_item: content_item)
  end

  def self.state(content_item)
    State.find_by!(content_item: content_item)
  end

  def self.semantic_version(content_item)
    SemanticVersion.find_by!(content_item: content_item)
  end

protected

  attr_accessor :scope
end
