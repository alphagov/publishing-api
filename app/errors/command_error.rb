class CommandError < StandardError
  attr_reader :code, :error_code, :error_details

  ERROR_CODES = %i[
    absolute_path_invalid
    action_invalid
    base_path_already_in_use
    base_path_invalid
    base_path_too_long
    bulk_publishing_flag_missing
    cannot_unpublish_with_draft
    conflict
    conflicting_unpublishing_flags
    content_id_alias_already_in_use
    content_store_validation_failed
    dns_hostname_invalid
    edition_missing
    edition_not_unique
    embedded_content_alias_not_found
    embedded_content_alias_not_found
    embedded_content_not_found
    explanation_missing_for_withdrawal
    fields_parameter_missing
    links_missing
    multiple_validation_errors
    no_draft_to_discard
    order_field_invalid
    parameter_missing_or_invalid
    publishing_app_missing
    redirect_destination_invalid
    redirect_destination_missing
    redirect_external_disallowed_domain
    redirect_external_govuk_should_be_internal
    redirect_external_missing_host
    redirect_external_not_https
    redirect_fragment_not_allowed_with_preserve
    redirect_path_equals_destination
    redirect_path_missing
    redirect_paths_not_unique
    redirect_query_not_allowed_with_preserve
    redirect_subdomain_invalid_chars
    redirect_subdomain_starts_with_hyphen
    redirect_subdomain_too_long
    redirects_missing_for_redirect
    redirects_must_include_base_path
    route_not_below_base_path
    route_path_missing
    route_paths_not_unique
    route_type_invalid
    route_type_missing
    route_unsupported_keys
    routes_must_include_base_path
    schema_validation_failed
    type_invalid
    type_missing
    unsupported_version_parameter
    update_type_invalid
    update_type_missing
    uuid_invalid
    validation_failed
  ].freeze

  def self.with_error_handling(ignore_404s: false, &block)
    block.call
  rescue GdsApi::HTTPServerError => e
    should_suppress = PublishingAPI.swallow_connection_errors && e.code == 502
    raise CommandError.new(code: e.code, message: e.message) unless should_suppress
  rescue GdsApi::HTTPClientError => e
    return if e.code == 404 && ignore_404s

    # ignore payload_version conflicts
    return if e.code == 409 && e.message =~ /transmitted_at|payload_version/

    fields = if e.error_details.present?
               e.error_details.fetch("errors", {})
             else
               {}
             end
    raise CommandError.new(
      code: e.code,
      **(e.code == 422 ? { error_code: :content_store_validation_failed } : {}),
      error_details: {
        error: {
          code: e.code,
          **(e.code == 422 ? { error_code: :content_store_validation_failed } : {}),
          message: e.message,
          fields:,
        },
      },
    )
  rescue GdsApi::BaseError => e
    raise CommandError.new(code: 500, message: "Unexpected error from the downstream application: #{e.message}")
  end

  # error_details: Hash(field_name: String => [error_messages]: Array(String))
  def initialize(code:, message: nil, error_code: nil, error_details: nil)
    raise "Invalid code #{code}" unless valid_code?(code)

    notify_or_raise("Descriptive error code missing for 422 error") if code == 422 && error_code.nil?
    notify_or_raise("Unknown error_code: #{error_code}. Code must be included in ERROR_CODES") if error_code && !ERROR_CODES.include?(error_code)

    @code = code
    @error_code = error_code
    @error_details = if error_details
                       error_details
                     elsif message
                       {
                         "error" => {
                           "code" => code,
                           **(error_code ? { "error_code" => error_code } : {}),
                           "message" => message,
                         },
                       }
                     else
                       {
                         "error" => {
                           "code" => code,
                         },
                       }
                     end
    super(message || error_details.to_s)
  end

  def valid_code?(code)
    [400, 404, 409, 413, 422, 500].include?(code)
  end

  def as_json(_options = nil)
    @error_details
  end

  def ok?
    false
  end

  def error?
    true
  end

  # True if this error represents a client error, ie. the problem lies with
  # request sent by the caller to the publishing API
  def client_error?
    (400..499).cover?(code)
  end

  # True if this error represents a server error, ie. the server had an
  # unexpected problem which meant that it was unable to process the
  # request. The request has not been processed and the client should retry.
  def server_error?
    (500..599).cover?(code)
  end

  def notify_or_raise(message)
    return GovukError.notify(message, level: "warning") if Rails.env.production?

    raise ArgumentError, message
  end
end
