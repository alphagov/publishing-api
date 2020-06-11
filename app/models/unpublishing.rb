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
    where(edition: edition).pick(:type) == "substitute"
  end
end
