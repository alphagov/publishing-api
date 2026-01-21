class EditionFinderService
  attr_reader :path, :content_store

  def initialize(path, content_store)
    @path = path
    @content_store = content_store
  end

  def find
    exact_match = scope.find_by(base_path: path)
    return exact_match if exact_match

    if route_matches.present?
      exact_route_match || best_prefix_match
    end
  end

private

  def scope
    Edition.where(content_store:)
  end

  def route_matches
    @route_matches ||= scope
      .where("routes @> ?", json_path_element(path, "exact"))
      # ANY will match any of the given array elements (similar to IN(), but for JSON arrays)
      # the ARRAY [?]::jsonb[] is typecasting for PostgreSQL's JSON operators
      .or(scope.where("routes @> ANY (ARRAY [?]::jsonb[])", potential_prefix_json_matches))
      .or(scope.where("redirects @> ?", json_path_element(path, "exact")))
      .or(scope.where("redirects @> ANY (ARRAY [?]::jsonb[])", potential_prefix_json_matches))
  end

  # Given a path, will decompose the path into path prefixes, and
  # return a JSON array element that can be matched against the
  # routes or redirects array in the scope
  def potential_prefix_json_matches
    potential_prefixes.map { |p| json_path_element(p, "prefix") }
  end

  def json_path_element(path, type)
    [{ path:, type: }].to_json
  end

  def potential_prefixes
    @potential_prefixes ||= begin
      paths = path.split("/").reject(&:empty?)
      (0...paths.size).map { |i| "/#{paths[0..i].join('/')}" }
    end
  end

  def exact_route_match
    route_matches.detect do |edition|
      routes_and_redirects(edition).any? do |route|
        route[:path] == path && route[:type] == "exact"
      end
    end
  end

  def best_prefix_match
    prefixes = potential_prefixes
    sorted = route_matches.sort_by do |edition|
      best_match = routes_and_redirects(edition)
        .select { |route| route[:type] == "prefix" && prefixes.include?(route[:path]) }
        .max_by { |route| route[:path].length }

      -best_match[:path].length
    end
    sorted.first
  end

  def routes_and_redirects(edition)
    edition.routes + edition.redirects
  end
end
