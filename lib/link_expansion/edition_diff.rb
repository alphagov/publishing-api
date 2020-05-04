class LinkExpansion::EditionDiff
  attr_reader :current_edition, :version

  def initialize(current_edition, version: nil, previous_edition: nil)
    @current_edition = current_edition
    @previous_edition = previous_edition
    @version = version
  end

  delegate :present?, to: :diff

  def fields
    diff.map(&:first)
  end

  def has_previous_edition?
    previous_edition.present?
  end

private

  def diff
    @diff ||= hash_diff(
      previous_edition_expanded,
      current_edition_expanded,
    )
  end

  def hash_diff(a, b) # rubocop:disable Naming/MethodParameterName
    a.size > b.size ? a.to_a - b.to_a : b.to_a - a.to_a
  end

  def previous_edition_expanded
    return {} unless has_previous_edition?

    ExpansionRules.expand_fields(previous_edition.to_h.deep_symbolize_keys,
                                 draft: true)
  end

  def current_edition_expanded
    ExpansionRules.expand_fields(current_edition.to_h.deep_symbolize_keys,
                                 draft: true)
  end

  def previous_edition
    @previous_edition ||=
      current_edition.document.editions.find_by(
        user_facing_version: previous_user_version,
      )
  end

  def previous_user_version
    current_user_version - 1
  end

  def current_user_version
    version || current_edition.user_facing_version
  end
end
