class ExpansionRules::MultiLevelLinks
  def initialize(multi_level_link_paths, backwards: false)
    @multi_level_link_paths = multi_level_link_paths
    @backwards = backwards
  end

  def allowed_link_types(link_types_path)
    @next_cache ||= {}
    @next_cache[link_types_path.to_s] ||= begin
      raise "Can't operate on an empty link_types_path" if link_types_path.empty?
      # look up all the paths for the next level and the level beyond it
      extra_item_1 = paths(length: link_types_path.length + 1)
      extra_item_2 = paths(length: link_types_path.length + 2)
      # match the next link for ones of these fit our provided paths
      (extra_item_1 + extra_item_2).uniq
        .map { |path| next_link_type_in_path(link_types_path, path) }
        .compact
        .uniq
    end
  end

  ##
  # Returns arrays of link paths that are calculated for the specified length
  # which works out what the various multi level link paths with recursive items
  # look like at a particular length
  # eg for a path [:test.recurring] of length 3 would be [:test, :test, :test]
  # when there are non recurring items in the path the shortest size possible
  # is returned eg [:test, :this.recurring] shortest length is 2
  def paths(length: 1)
    @paths_cache ||= {}
    @paths_cache[length] ||= begin
      paths = multi_level_link_paths.map do |path|
        recurring = path.count { |a| a.is_a?(Array) }
        raise "Only 1 recurring item supported" if recurring > 1
        non_recurring = path.count - recurring
        cycles = [1, length - non_recurring].max
        path.flat_map { |item| item.is_a?(Array) ? item.cycle(cycles).to_a : item }
      end
      backwards ? paths.map(&:reverse) : paths
    end
  end

  ##
  # For an array of link types return a hash mapping each of these to an array
  # of allowed links
  def next_allowed_link_types(link_types, link_types_path)
    link_types.each_with_object({}) do |link_type, memo|
      next_links = allowed_link_types(link_types_path + [link_type])
      memo[link_type] = next_links unless next_links.empty?
    end
  end

private

  attr_reader :multi_level_link_paths, :backwards

  def next_link_type_in_path(current_path, path_to_check)
    if backwards
      range = path_to_check.length - current_path.length
      # find an index of where the current path matches the path_to_check
      matching_index = (0..range).find do |index|
        check_length = index + current_path.length
        path_to_check[index...check_length] == current_path
      end
      path_to_check[matching_index + current_path.length] if matching_index
    else
      match = path_to_check[0...current_path.length] == current_path
      path_to_check[current_path.length] if match
    end
  end
end
