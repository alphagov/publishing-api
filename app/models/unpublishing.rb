class Unpublishing < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :content_item, class_name: Edition

  VALID_TYPES = %w(
    gone
    vanish
    redirect
    substitute
    withdrawal
  ).freeze

  validates :content_item, presence: true, uniqueness: true
  validates :type, presence: true, inclusion: { in: VALID_TYPES }
  validates :explanation, presence: true, if: :withdrawal?
  validates :alternative_path, presence: true, if: :redirect?
  validates_with UnpublishingRedirectValidator

  def withdrawal?
    type == "withdrawal"
  end

  def redirect?
    type == "redirect"
  end

  def self.is_substitute?(content_item)
    where(content_item: content_item).pluck(:type).first == "substitute"
  end
end
