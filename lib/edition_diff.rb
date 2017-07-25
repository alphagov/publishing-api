class EditionDiff
  attr_reader :current_edition, :version

  def initialize(current_edition, version: nil, previous_edition: nil)
    @current_edition = current_edition
    @previous_edition = previous_edition
    @version = version
  end

  def field_diff
    ExpansionRules.potential_expansion_fields(current_edition.document_type) &
      diff.map(&:first)
  end

private

  def diff
    hash_diff(
      @previous_edition ? @previous_edition.to_h.deep_symbolize_keys : previous_edition.to_h.deep_symbolize_keys,
      current_edition.to_h.deep_symbolize_keys
    )
  end

  def hash_diff(a, b)
    a.size > b.size ? a.to_a - b.to_a : b.to_a - a.to_a
  end

  def previous_edition
    @previous_edition ||
      current_edition.document.editions.find_by(
        user_facing_version: previous_user_version
    )
  end

  def previous_user_version
    current_user_version - 1
  end

  def current_user_version
    version || current_edition.user_facing_version
  end
end
