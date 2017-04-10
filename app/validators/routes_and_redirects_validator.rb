class RoutesAndRedirectsValidator < ActiveModel::Validator
  def validate(record, base_path: nil)
    base_path = record.base_path if base_path.nil?

    return unless base_path.present?

    routes = record.try(:routes) || []
    redirects = record.try(:redirects) || []

    routes.each do |route|
      RouteValidator.new.validate(record, :routes, route, base_path)
    end

    redirects.each do |redirect|
      RouteValidator.new.validate(record, :redirects, redirect, base_path)
      RedirectValidator.new.validate(record, redirect)
    end

    must_have_unique_paths(record, routes, redirects)

    if check_redirects?(record)
      redirects_must_include_base_path(record, base_path, redirects)
    else
      routes_must_include_base_path(record, base_path, routes)
    end
  end

private

  def check_redirects?(record)
    return record.schema_name == "redirect" if record.respond_to?(:schema_name)
    record.redirect?
  end

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

  def redirects_must_include_base_path(record, base_path, redirects)
    if redirects.none? { |r| r[:path] == base_path }
      record.errors[:redirects] << "must include the base path"
    end
  end

  def routes_must_include_base_path(record, base_path, routes)
    if routes.none? { |r| r[:path] == base_path }
      record.errors[:routes] << "must include the base path"
    end
  end

  class RouteValidator
    def validate(record, attribute, route, base_path)
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
        record.errors[attribute] << "unsupported keys: #{unsupported_keys.join(', ')}"
      end

      validator = AbsolutePathValidator.new(attributes: attribute)
      validator.validate_each(record, attribute, path)

      unless path.present? && below_base_path?(path, base_path)
        record.errors[attribute] << "path must be below the base path"
      end
    end

  private

    def below_base_path?(path, base_path)
      return true if path =~ %r(^#{base_path}\.[\w-]+\z)

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
      path = redirect[:path]
      destination = redirect[:destination]

      unless path.present?
        record.errors[:redirects] << "path must be present"
      end

      unless destination.present?
        record.errors[:redirects] << "destination must be present"
      end

      if path == destination
        record.errors[:redirects] << "path cannot equal the destination"
      end

      unless valid_exact_redirect_target?(destination)
        record.errors[:redirects] << "is not a valid redirect destination"
      end
    end

  private

    def acceptable_destination?(target)
      target.starts_with?("/") || valid_govuk_campaign_url?(target)
    end

    def valid_govuk_campaign_url?(target)
      uri = URI.parse(target)
      host = uri.host
      if host =~ /\A.+\.campaign\.gov\.uk\z/i && uri.scheme == "https"
        label = host.split(".").first
        label.present? && valid_subdomain?(label)
      end
    rescue
      false
    end

    def valid_subdomain?(label)
      valid_dns_label_range?(label) &&
        starts_without_hyphen?(label) &&
        contains_alphnumeric_or_hyphen?(label)
    end

    def valid_dns_label_range?(label)
      (1..63) === label.length
    end

    def starts_without_hyphen?(label)
      label =~ /\A[^-].*[^-]\z/i
    end

    def contains_alphnumeric_or_hyphen?(label)
      label =~ /\A[a-z0-9\-]*\z/i
    end

    def valid_exact_redirect_target?(target)
      return false unless target.present? && acceptable_destination?(target)

      uri = URI.parse(target)
      expected = ""
      expected << "#{uri.scheme}://" if uri.scheme.present?
      expected << uri.host if uri.host.present?
      expected << uri.path if uri.path.present?
      expected << "?#{uri.query}" if uri.query.present?
      expected << "##{uri.fragment}" if uri.fragment.present?
      expected == target
    rescue URI::InvalidURIError
      false
    end
  end
end
