
class RoutesAndRedirectsValidator < ActiveModel::Validator
  include CustomRecordInvalidHelper

  EXTERNAL_HOST_ALLOW_LIST = %w[
    caa.co.uk
    gov.uk
    independent-inquiry.uk
    internationalaisafetyreport.org
    judiciary.uk
    moneyhelper.org.uk
    nationalhighways.co.uk
    nhs.uk
    police.uk
    pubscodeadjudicator.org.uk
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
      add_error(record, :routes, "must have unique paths", :routes_not_unique)
    end

    paths += redirects.map { |r| r[:path] }
    unless paths == paths.uniq
      add_error(record, :redirects, "must have unique paths", :redirects_not_unique)
    end
  end

  def redirects_must_include_base_path(record, base_path, redirects)
    if redirects.none? { |r| r[:path] == base_path }
      add_error(record, :redirects, "must include the base path", :redirects_must_include_base_path)
    end
  end

  def routes_must_include_base_path(record, base_path, routes)
    if routes.none? { |r| r[:path] == base_path }
      add_error(record, :routes, "must include the base path", :routes_must_include_base_path)
    end
  end

  class RouteValidator
    include CustomRecordInvalidHelper

    def validate(record, attribute, route, base_path)
      type = route[:type]
      path = route[:path]

      if type.blank?
        add_error(record, attribute, "type must be present", :route_type_missing)
      end

      if path.blank?
        add_error(record, attribute, "path must be present", :route_path_missing)
      end

      unless type.present? && %w[exact prefix].include?(type)
        add_error(record, attribute, "type must be either 'exact' or 'prefix'", :route_type_invalid)
      end

      unsupported_keys = additional_keys(route, attribute)
      if unsupported_keys.any?
        add_error(record, attribute, "unsupported keys: #{unsupported_keys.join(', ')}", :route_unsupported_keys)
      end

      validator = AbsolutePathValidator.new(attributes: attribute)
      validator.validate_each(record, attribute, path)

      unless path.present? && below_base_path?(path, base_path)
        add_error(record, attribute, "path must be below the base path", :route_not_below_base_path)
      end
    end

  private

    def below_base_path?(path, base_path)
      path.start_with?(base_path)
    end

    def additional_keys(route, attribute)
      utilised_keys = route.keys.uniq

      supported_keys = %i[path type]
      supported_keys += %i[destination segments_mode] if attribute == :redirects

      utilised_keys - supported_keys
    end
  end

  class RedirectValidator
    include CustomRecordInvalidHelper

    attr_reader :redirect, :errors, :record

    def initialize(record, redirect)
      @record = record
      @redirect = redirect
      @errors = record.errors
    end

    def validate
      path = redirect[:path]
      destination = redirect[:destination]

      add_error(:redirects, "path must be present", :redirect_path_missing) if path.blank?
      add_error(:redirects, "destination must be present", :redirect_destination_missing) if destination.blank?
      add_error(:redirects, "path cannot equal the destination", :redirect_path_equals_destination) if path == destination
      return unless errors.empty?
      
      add_error(:redirects, 
        "destination invalid (#{destination})", :redirect_destination_invalid) if invalid_destination?(destination)
      
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

      EXTERNAL_HOST_ALLOW_LIST.any? { |allowed| host.end_with?(".#{allowed}") }
    end

    def invalid_destination?(destination)
      uri = URI.parse(destination)
      !url_constructed_as_expected?(destination, uri)
    rescue URI::InvalidURIError
      true
    end

    def validate_internal_redirect(destination)
      if destination != "/" && destination.end_with?("/")
        add_error(:redirects, "destination invalid (#{destination}), internal redirects cannot end with /", :redirect_destination_invalid)
      end
    end

    def validate_external_redirect(destination)
      uri = URI.parse(destination)

      if uri.host.nil?
        add_error(:redirects, "missing host for external redirect (#{destination})", :redirect_external_missing_host)
        return
      end

      add_error(:redirects, "external redirects only accepted for the domains #{EXTERNAL_HOST_ALLOW_LIST.to_sentence} (#{destination})", :redirect_external_domain_not_allowed) unless government_domain?(uri.host)

      add_error(:redirects, "internal redirect should not be specified with full url (#{destination})", :redirect_external_govuk_should_be_internal) if %w[gov.uk www.gov.uk].include?(uri.host)

      add_error(:redirects, "external redirects must use https (#{destination})", :redirect_external_not_https) unless uri.scheme == "https"

      uri.host.split(".").each { |subdomain| validate_subdomain(subdomain) }
    end

    def validate_subdomain(subdomain)
      prefix = "subdomain #{subdomain}"
      add_error(:redirects, "#{prefix} is longer than 63 characters", :redirect_subdomain_too_long) if
        subdomain.length > 63
      add_error(:redirects, "#{prefix} should not start with a hyphen", :redirect_subdomain_starts_with_hyphen) if
        subdomain.starts_with?("-")
      add_error(:redirects, "#{prefix} contains prohibited characters", :redirect_subdomain_invalid_chars) unless
        subdomain =~ /\A[a-z0-9-]*\z/i
    end

    def reject_query_parameters_and_fragment(destination)
      uri = URI.parse(destination)

      if uri.fragment.present?
        add_error(:redirects, "destination #{destination} cannot contain a fragment if the segments_mode is 'preserve'", :redirect_fragment_not_allowed_with_preserve)
      end

      if uri.query.present?
        add_error(:redirects, "destination #{destination} cannot contain query parameters if the segments_mode is 'preserve'", :redirect_query_not_allowed_with_preserve)
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
