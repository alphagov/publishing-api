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
