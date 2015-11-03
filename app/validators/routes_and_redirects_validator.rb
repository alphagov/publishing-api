class RoutesAndRedirectsValidator < ActiveModel::Validator
  def validate(record)
    return unless record.base_path.present?

    routes = record.routes || []
    redirects = record.redirects || []

    routes.each do |route|
      RouteValidator.new.validate(record, :routes, route)
    end

    redirects.each do |redirect|
      RouteValidator.new.validate(record, :redirects, redirect)
      RedirectValidator.new.validate(record, redirect)
    end

    must_have_unique_paths(record, routes, redirects)

    if record.format == "redirect"
      redirects_must_not_have_routes(record, routes)
      redirects_must_include_base_path(record, redirects)
    else
      routes_must_include_base_path(record, routes)
    end
  end

  private

  def must_have_unique_paths(record, routes, redirects)
    paths = routes.map { |r| r[:path] }
    unless paths == paths.uniq
      record.errors[:routes] << "must have unique paths"
    end

    paths += redirects.map { |r| r[:path] }
    unless paths == paths.uniq
      record.errors[:redirects] << "must have unique paths"
    end
  end

  def redirects_must_not_have_routes(record, routes)
    if routes.any?
      record.errors[:routes] << "redirect items cannot have routes"
    end
  end

  def redirects_must_include_base_path(record, redirects)
    if redirects.none? { |r| r[:path] == record.base_path }
      record.errors[:redirects] << "must include the base path"
    end
  end

  def routes_must_include_base_path(record, routes)
    if routes.none? { |r| r[:path] == record.base_path }
      record.errors[:routes] << "must include the base path"
    end
  end

  class RouteValidator
    def validate(record, attribute, route)
      type = route[:type]
      path = route[:path]

      unless type.present?
        record.errors[attribute] << "type must be present"
      end

      unless path.present?
        record.errors[attribute] << "path must be present"
      end

      unless type.present? && %(exact prefix).include?(type)
        record.errors[attribute] << "type must be either 'exact' or 'prefix'"
      end

      unsupported_keys = additional_keys(route, attribute)
      if unsupported_keys.any?
        record.errors[attribute] << "unsupported keys: #{unsupported_keys.join(", ")}"
      end

      validator = AbsolutePathValidator.new(attributes: attribute)
      validator.validate_each(record, attribute, path)

      unless path.present? && below_base_path?(path, record.base_path)
        record.errors[attribute] << "path must be below the base path"
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
    def validate(record, redirect)
      destination = redirect[:destination]
      type = redirect[:type]

      unless destination.present?
        record.errors[:redirects] << "destination must be present"
      end

      if type == "exact"
        unless valid_exact_redirect_target?(destination)
          record.errors[:redirects] << "is not a valid redirect destination"
        end
      else
        validator = AbsolutePathValidator.new(attributes: :redirects)
        validator.validate_each(record, :redirects, destination)
      end
    end

  private
    def valid_exact_redirect_target?(target)
      return false unless target.present? and target.starts_with?("/")

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
