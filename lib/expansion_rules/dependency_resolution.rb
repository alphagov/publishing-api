class ExpansionRules::DependencyResolution
  def initialize(rules)
    @rules = rules
    @multi_level_links = ExpansionRules::MultiLevelLinks.new(
      rules::MULTI_LEVEL_LINK_PATHS,
      backwards: true
    )
  end

  def allowed_link_types(link_types_path)
    multi_level_links.allowed_link_types(link_types_path)
  end

  def allowed_direct_link_types(link_types_path)
    allowed_link_types(link_types_path).select do |link_type|
      !rules.is_reverse_link_type?(link_type)
    end
  end

  def allowed_reverse_link_types(link_types_path)
    allowed_link_types(link_types_path).select do |link_type|
      rules.is_reverse_link_type?(link_type)
    end
  end

  def next_allowed_link_types(link_types, link_types_path = [])
    if link_types.nil?
      link_types = rules::MULTI_LEVEL_LINK_PATHS.flat_map(&:last)
        .select { |link_type| !rules.is_reverse_link_type?(link_type) }
    end

    multi_level_links.next_allowed_link_types(link_types, link_types_path)
  end

  def next_allowed_direct_link_types(link_types, link_types_path = [])
    next_allowed = next_allowed_link_types(link_types, link_types_path)
    rules.next_allowed_direct_link_types(next_allowed)
  end

  def next_allowed_reverse_link_types(link_types, link_types_path = [], unreverse: false)
    next_allowed = next_allowed_link_types(link_types, link_types_path)
    rules.next_allowed_reverse_link_types(next_allowed, unreverse: unreverse)
  end

  def valid_link_types_path?(link_types_path)
    valid_paths = multi_level_links.paths(
      length: link_types_path.length,
    )
    valid_paths.any? { |path| path[0...link_types_path.length] == link_types_path }
  end

private

  attr_reader :rules, :multi_level_links
end
