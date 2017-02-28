require 'hashdiff'

class EditionDiff
  attr_reader :current_edition, :version
  NullEdition = Struct.new(:id)

  def initialize(current_edition, version: nil, previous_edition: nil)
    @current_edition = current_edition
    @previous_edition = previous_edition
    @version = version
  end

  def field_diff
    diff.map { |_, field, _| field.to_sym }
  end

private

  def diff
    HashDiff.best_diff(
      @previous_edition ? @previous_edition : presented_item(previous_edition.id),
      presented_item(current_edition.id))
  end

  def previous_edition
    @previous_edition || Document.find_by(content_id: current_edition.document.content_id)
      .editions.find_by(user_facing_version: previous_user_version) || NullEdition.new
  end

  def previous_user_version
    current_user_version - 1
  end

  def current_user_version
    version || current_edition.user_facing_version
  end

  def presented_item(id)
    Presenters::DownstreamPresenter.present(
      Queries::GetWebContentItems.find(id),
      state_fallback_order: [:draft, :published]
    ).deep_stringify_keys
  end
end
