class Unpublishing < ApplicationRecord
  include SymbolizeJSON

  self.inheritance_column = nil

  belongs_to :edition

  VALID_TYPES = %w[
    gone
    vanish
    redirect
    substitute
    withdrawal
  ].freeze

  validates :edition, presence: true, uniqueness: true
  validates :type, presence: true, inclusion: { in: VALID_TYPES }
  validates :explanation, presence: true, if: :withdrawal?
  validates :redirects, presence: true, if: :redirect?

  validate if: :redirect? do
    RoutesAndRedirectsValidator.new
      .validate(self, base_path: edition.base_path)
  end

  def gone?
    type == "gone"
  end

  def withdrawal?
    type == "withdrawal"
  end

  def redirect?
    type == "redirect"
  end

  def substitute?
    type == "substitute"
  end

  def self.is_substitute?(edition)
    where(edition:).pick(:type) == "substitute"
  end

  def save!(*args)
    super
  rescue ActiveRecord::RecordInvalid => e
    add_error_codes!(e.record)

    raise e
  end

private

  ERROR_CODE_MAP = {
    %i[edition blank] => :edition_missing,
    %i[edition taken] => :edition_not_unique,
    %i[type blank] => :type_missing,
    %i[type inclusion] => :type_invalid,
    %i[explanation blank] => :explanation_missing_for_withdrawal,
    %i[redirects blank] => :redirects_missing_for_redirect,
  }.freeze

  def add_error_codes!(record)
    record.errors.each do |error|
      error.options[:code] ||= ERROR_CODE_MAP[[error.attribute, error.type]] || :validation_failed
    end
  end
end
