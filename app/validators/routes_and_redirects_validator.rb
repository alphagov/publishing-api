class RoutesAndRedirectsValidator < ActiveModel::Validator
  def validate(record)
    return unless record.base_path.present?

    record.routes.each do |route|
      RouteValidator.new.validate(record, :routes, route)
    end

    record.redirects.each do |redirect|
      RouteValidator.new.validate(record, :redirects, redirect)
      RedirectValidator.new.validate(record, redirect)
    end

    paths = record.routes.map { |r| r[:path] }
    unless paths == paths.uniq
      record.errors[:routes] << "must have unique paths"
    end

    paths += record.redirects.map { |r| r[:path] }
    unless paths == paths.uniq
      record.errors[:redirects] << "must have unique paths"
    end

    if record.format == "redirect" && record.routes.any?
      record.errors[:routes] << "redirect items cannot have routes"
    end

    if record.format != "redirect" && record.routes.none? { |r| r[:path] == record.base_path }
      record.errors[:routes] << "must include the base path"
    end

    if record.format == "redirect" && record.redirects.none? { |r| r[:path] == record.base_path }
      record.errors[:redirects] << "must include the base path"
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

      unless %(exact prefix).include?(type)
        record.errors[attribute] << "type must be either 'exact' or 'prefix'"
      end

      validator = AbsolutePathValidator.new(attributes: attribute)
      validator.validate_each(record, attribute, path)

      unless below_base_path?(path, record.base_path)
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
