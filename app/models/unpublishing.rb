class Unpublishing < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :edition

  VALID_TYPES = %w(
    gone
    vanish
    redirect
    substitute
    withdrawal
  ).freeze

  validates :edition, presence: true, uniqueness: true
  validates :type, presence: true, inclusion: { in: VALID_TYPES }
  validates :explanation, presence: true, if: :withdrawal?
  validates :alternative_path, presence: true, if: :redirect?
  validates :redirects, presence: true, if: :redirect?
  validates_with UnpublishingRedirectValidator

  before_validation do
    self.redirects = [{ path: alternative_path, type: "exact" }] if redirect?
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

  def self.is_substitute?(edition)
    where(edition: edition).pluck(:type).first == "substitute"
  end
end
