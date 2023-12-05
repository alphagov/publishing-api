class FindByPath
  attr_reader :model_class

  def initialize(model_class)
    @model_class = model_class
  end

  def find(path)
    exact_match = model_class.where(base_path: path).take(1).first
    return exact_match if exact_match

    matches = find_route_matches(path)

    if matches.count.positive?
      best_route_match(matches, path)
    end
  end

private

  def find_route_matches(path)
    query = model_class
      .where("routes  @> ?", json_path_element(path, "exact"))
      # ANY will match any of the given array elements (similar to IN(), but for JSON arrays)
      # the ARRAY [?]::jsonb[] is typecasting for PostgreSQL's JSON operators
      .or(model_class.where("routes @> ANY (ARRAY [?]::jsonb[])", potential_prefix_json_matches(path)))

    if model_class.attribute_names.include?("redirects")
      query = query
      .or(model_class.where("redirects  @> ?", json_path_element(path, "exact")))
      .or(model_class.where("redirects @> ANY (ARRAY [?]::jsonb[])", potential_prefix_json_matches(path)))
    end
    query
  end

  # Given a path, will decompose the path into path prefixes, and
  # return a JSON array element that can be matched against the
  # routes or redirects array in the model_class
  def potential_prefix_json_matches(path)
    potential_prefixes(path).map { |p| json_path_element(p, "prefix") }
  end

  def json_path_element(path, type)
    [{ path:, type: }].to_json
  end

  def best_route_match(matches, path)
    exact_route_match(matches, path) || best_prefix_match(matches, path)
  end

  def potential_prefixes(path)
    paths = path.split("/").reject(&:empty?)
    (0...paths.size).map { |i| "/#{paths[0..i].join('/')}" }
  end

  def exact_route_match(matches, path)
    matches.detect do |item|
      routes_and_redirects(item).any? do |route|
        route["path"] == path && route["type"] == "exact"
      end
    end
  end

  def best_prefix_match(matches, path)
    prefixes = potential_prefixes(path)
    sorted = matches.sort_by do |item|
      best_match = routes_and_redirects(item)
        .select { |route| route["type"] == "prefix" && prefixes.include?(route["path"]) }
        .min_by { |route| -route["path"].length }

      -best_match["path"].length
    end
    sorted.first
  end

  def routes_and_redirects(item)
    item.routes + (item.respond_to?(:redirects) ? item.redirects : [])
  end
end
