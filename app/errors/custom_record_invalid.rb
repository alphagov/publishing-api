class CustomRecordInvalid < ActiveRecord::RecordInvalid
  attr_reader :error_code

  ERROR_CODES = %i[
    base_path_already_reserved
    base_path_invalid
    base_path_too_long
    publishing_app_missing
    edition_missing
    edition_not_unique
    type_missing
    type_invalid
    explanation_missing_for_withdrawal
    redirects_missing_for_redirect
    routes_not_unique
    redirects_not_unique
    redirects_must_include_base_path
    routes_must_include_base_path
    route_type_missing
    route_path_missing
    route_type_invalid
    route_unsupported_keys
    route_not_below_base_path
    absolute_path_invalid
    redirect_path_missing
    redirect_destination_missing
    redirect_path_equals_destination
    redirect_destination_invalid
    redirect_external_missing_host
    redirect_external_domain_not_allowed
    redirect_external_govuk_should_be_internal
    redirect_external_not_https
    redirect_subdomain_too_long
    redirect_subdomain_starts_with_hyphen
    redirect_subdomain_invalid_chars
    redirect_fragment_not_allowed_with_preserve
    redirect_query_not_allowed_with_preserve
    validation_failed
  ].freeze

  def initialize(record, error_code:)
    raise ArgumentError, "Unknown error_code: #{error_code}" unless ERROR_CODES.include?(error_code)

    @error_code = error_code
    super(record)
  end
end
