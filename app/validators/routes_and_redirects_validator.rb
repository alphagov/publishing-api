class RoutesAndRedirectsValidator < ActiveModel::Validator
  EXTERNAL_HOST_ALLOW_LIST = %w[
    caa.co.uk
    gov.uk
    judiciary.uk
    moneyhelper.org.uk
    nationalhighways.co.uk
    nhs.uk
    police.uk
    ukri.org
  ].freeze

  def validate(record, base_path: nil)
    base_path = record.base_path if base_path.nil?

    return if base_path.blank?

    routes = record.try(:routes) || []
    redirects = record.try(:redirects) || []

    routes.each do |route|
      RouteValidator.new.validate(record, :routes, route, base_path)
    end

    redirects.each do |redirect|
      RouteValidator.new.validate(record, :redirects, redirect, base_path)
      RedirectValidator.new(record, redirect).validate
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
      record.errors.add(:routes, "must have unique paths")
    end

    paths += redirects.map { |r| r[:path] }
    unless paths == paths.uniq
      record.errors.add(:redirects, "must have unique paths")
    end
  end

  def redirects_must_include_base_path(record, base_path, redirects)
    if redirects.none? { |r| r[:path] == base_path }
      record.errors.add(:redirects, "must include the base path")
    end
  end

  def routes_must_include_base_path(record, base_path, routes)
    if routes.none? { |r| r[:path] == base_path }
      record.errors.add(:routes, "must include the base path")
    end
  end

  class RouteValidator
    def validate(record, attribute, route, base_path)
      type = route[:type]
      path = route[:path]

      if type.blank?
        record.errors.add(attribute, "type must be present")
      end

      if path.blank?
        record.errors.add(attribute, "path must be present")
      end

      unless type.present? && %(exact prefix).include?(type)
        record.errors.add(attribute, "type must be either 'exact' or 'prefix'")
      end

      unsupported_keys = additional_keys(route, attribute)
      if unsupported_keys.any?
        record.errors.add(attribute, "unsupported keys: #{unsupported_keys.join(', ')}")
      end

      validator = AbsolutePathValidator.new(attributes: attribute)
      validator.validate_each(record, attribute, path)

      unless path.present? && below_base_path?(path, base_path)
        record.errors.add(attribute, "path must be below the base path")
      end
    end

  private

    def below_base_path?(path, base_path)
      return true if path =~ %r{^#{base_path}\.[\w-]+\z}

      suffix = /\.([\w-]+\z)$/.match(base_path).to_a&.first || ""
      base_path_without_suffix = base_path.gsub(suffix, "")

      /^#{base_path_without_suffix}.*#{suffix}/.match?(path)
    end

    def segments(path)
      path.split("/").reject(&:blank?)
    end

    def additional_keys(route, attribute)
      utilised_keys = route.keys.uniq

      supported_keys = %i[path type]
      if attribute == :redirects
        supported_keys += %i[
          destination
          segments_mode
          redirect_type
        ]
      end

      utilised_keys - supported_keys
    end
  end

  class RedirectValidator
    attr_reader :redirect, :errors

    def initialize(record, redirect)
      @redirect = redirect
      @errors = record.errors
    end

    def validate
      path = redirect[:path]
      destination = redirect[:destination]

      errors.add(:redirects, "path must be present") if path.blank?
      errors.add(:redirects, "destination must be present") if destination.blank?
      errors.add(:redirects, "path cannot equal the destination") if path == destination
      return unless errors.empty?

      errors.add(:redirects, "destination invalid (#{destination})") if invalid_destination?(destination)
      return unless errors.empty?

      if internal?(destination)
        validate_internal_redirect(destination)
      else
        validate_external_redirect(destination)
      end

      if redirect[:segments_mode] == "preserve"
        # When the segments mode is preserve, the query parameters from the
        # incoming url will be appended on to the destination. If the route type
        # is prefix, in addition to the query parameters, part of the incoming
        # path may also be appended.

        # This validation prevents the introduction of redirects where the
        # destination contains a fragment or where the destination has query
        # parameters, as its unlikely that these are appropriate to use when the
        # segments mode is preserve.
        reject_query_parameters_and_fragment(destination)
      end
    end

  private

    def internal?(destination)
      destination.starts_with?("/")
    end

    def government_domain?(host)
      return true if EXTERNAL_HOST_ALLOW_LIST.include?(host)

      host_allow_list_for_subdomains = EXTERNAL_HOST_ALLOW_LIST.map { |allowed_host| ".#{allowed_host}" }
      host.end_with?(*host_allow_list_for_subdomains)
    end

    def invalid_destination?(destination)
      uri = URI.parse(destination)
      !url_constructed_as_expected?(destination, uri)
    rescue URI::InvalidURIError
      true
    end

    def validate_internal_redirect(destination)
      errors.add(:redirects, "destination invalid (#{destination}), internal redirects cannot end with /") if
        destination != "/" && (destination.end_with? "/")
    end

    def validate_external_redirect(destination)
      uri = URI.parse(destination)

      if uri.host.nil?
        errors.add(:redirects, "missing host for external redirect (#{destination})")
        return
      end

      errors.add(:redirects, "external redirects only accepted for the domains #{EXTERNAL_HOST_ALLOW_LIST.to_sentence} (#{destination})") unless
        government_domain?(uri.host)

      errors.add(:redirects, "internal redirect should not be specified with full url (#{destination})") if
        %w[gov.uk www.gov.uk].include? uri.host

      errors.add(:redirects, "external redirects must use https (#{destination})") unless uri.scheme == "https"

      uri.host.split(".").each { |subdomain| validate_subdomain(subdomain) }
    end

    def validate_subdomain(subdomain)
      prefix = "subdomain #{subdomain}"
      errors.add(:redirects, "#{prefix} is longer than 63 characters") if
        subdomain.length > 63
      errors.add(:redirects, "#{prefix} should not start with a hyphen") if
        subdomain.starts_with?("-")
      errors.add(:redirects, "#{prefix} contains prohibited characters") unless
        subdomain =~ /\A[a-z0-9-]*\z/i
    end

    def reject_query_parameters_and_fragment(destination)
      uri = URI.parse(destination)

      if uri.fragment.present?
        errors.add(:redirects, "destination #{destination} cannot contain a fragment if the segments_mode is 'preserve'")
      end
      if uri.query.present?
        errors.add(:redirects, "destination #{destination} cannot contain query parameters if the segments_mode is 'preserve'")
      end
    end

    def url_constructed_as_expected?(target, uri)
      expected = ""
      expected << "#{uri.scheme}://" if uri.scheme.present?
      expected << uri.host if uri.host.present?
      expected << uri.path if uri.path.present?
      expected << "?#{uri.query}" if uri.query.present?
      expected << "##{uri.fragment}" if uri.fragment.present?
      expected == target
    end
  end
end
