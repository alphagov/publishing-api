class RoutesAndRedirectsValidator < ActiveModel::Validator
  def validate(location)
    content_item = location.content_item
    base_path = location.base_path

    return unless content_item.present?
    return unless base_path.present?

    routes = content_item.routes || []
    redirects = content_item.redirects || []
    document_type = content_item.document_type

    routes.each do |route|
      RouteValidator.new.validate(location, :routes, route)
    end

    redirects.each do |redirect|
      RouteValidator.new.validate(location, :redirects, redirect)
      RedirectValidator.new.validate(location, redirect)
    end

    must_have_unique_paths(location, routes, redirects)

    if document_type == "redirect"
      redirects_must_not_have_routes(location, routes)
      redirects_must_include_base_path(location, redirects)
    else
      routes_must_include_base_path(location, routes)
    end
  end

private

  def must_have_unique_paths(location, routes, redirects)
    paths = routes.map { |r| r[:path] }
    unless paths == paths.uniq
      location.errors[:routes] << "must have unique paths"
    end

    paths += redirects.map { |r| r[:path] }
    unless paths == paths.uniq
      location.errors[:redirects] << "must have unique paths"
    end
  end

  def redirects_must_not_have_routes(location, routes)
    if routes.any?
      location.errors[:routes] << "redirect items cannot have routes"
    end
  end

  def redirects_must_include_base_path(location, redirects)
    if redirects.none? { |r| r[:path] == location.base_path }
      location.errors[:redirects] << "must include the base path"
    end
  end

  def routes_must_include_base_path(location, routes)
    if routes.none? { |r| r[:path] == location.base_path }
      location.errors[:routes] << "must include the base path"
    end
  end

  class RouteValidator
    def validate(location, attribute, route)
      type = route[:type]
      path = route[:path]

      unless type.present?
        location.errors[attribute] << "type must be present"
      end

      unless path.present?
        location.errors[attribute] << "path must be present"
      end

      unless type.present? && %(exact prefix).include?(type)
        location.errors[attribute] << "type must be either 'exact' or 'prefix'"
      end

      unsupported_keys = additional_keys(route, attribute)
      if unsupported_keys.any?
        location.errors[attribute] << "unsupported keys: #{unsupported_keys.join(', ')}"
      end

      validator = AbsolutePathValidator.new(attributes: attribute)
      validator.validate_each(location, attribute, path)

      unless path.present? && below_base_path?(path, location.base_path)
        location.errors[attribute] << "path must be below the base path"
      end
    end

  private

    def below_base_path?(path, base_path)
      return true if path.match(%r(^#{base_path}\.[\w-]+\z))

      path_segments = segments(path)
      base_segments = segments(base_path)

      pairs = base_segments.zip(path_segments)
      pairs.all? { |a, b| a == b }
    end

    def segments(path)
      path.split('/').reject(&:blank?)
    end

    def additional_keys(route, attribute)
      utilised_keys = route.keys.uniq

      supported_keys = [:path, :type]
      supported_keys << :destination if attribute == :redirects

      utilised_keys - supported_keys
    end
  end

  class RedirectValidator
    def validate(location, redirect)
      destination = redirect[:destination]
      type = redirect[:type]

      unless destination.present?
        location.errors[:redirects] << "destination must be present"
      end

      if type == "exact"
        unless valid_exact_redirect_target?(destination)
          location.errors[:redirects] << "is not a valid redirect destination"
        end
      else
        validator = AbsolutePathValidator.new(attributes: :redirects)
        validator.validate_each(location, :redirects, destination)
      end
    end

  private

    def valid_exact_redirect_target?(target)
      return false unless target.present? && target.starts_with?("/")

      uri = URI.parse(target)
      expected = uri.path
      expected << "?#{uri.query}" if uri.query.present?
      expected << "##{uri.fragment}" if uri.fragment.present?
      expected == target
    rescue URI::InvalidURIError
      false
    end
  end
end
