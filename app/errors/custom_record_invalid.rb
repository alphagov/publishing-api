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
    validation_failed
  ].freeze

  def initialize(record, error_code:)
    raise ArgumentError, "Unknown error_code: #{error_code}" unless ERROR_CODES.include?(error_code)

    @error_code = error_code
    super(record)
  end
end
