class RegisterableRedirect < RegisterableRoute

  validates :destination, presence: true
  validates :destination, absolute_path: true, unless: :exact?
  validate :validate_exact_redirect_destination, if: :exact?

private
  def validate_exact_redirect_destination
    unless valid_exact_redirect_target?(destination)
      errors[:destination] << "is not a valid redirect destination"
    end
  end

  # Valid 'exact' redirect targets differ from standard targets in that we
  # allow:
  # 1. Query strings
  # 2. Fragments
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
