class HashdiffBuilder
  def initialize(presenter)
    @presenter = presenter
  end

  def previous_item=(previous_item)
    @previous_item = presenter ? presenter.call(previous_item) : previous_item
  end

  def current_item=(current_item)
    @current_item = presenter ? presenter.call(current_item) : current_item
  end

  def diff
    raise MissingItemError, "No previous item provided" if previous_item.nil?
    raise MissingItemError, "No current item provided" if current_item.nil?

    create_diff(previous_item, current_item)
  end

private

  attr_reader :presenter, :previous_item, :current_item

  def create_diff(previous_item, current_item)
    Hashdiff.diff(
      previous_item, current_item, array_path: true, use_lcs: false
    )
  end

  class MissingItemError < RuntimeError; end
end
