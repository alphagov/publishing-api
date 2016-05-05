class Unpublishing < ActiveRecord::Base
  self.inheritance_column = nil

  belongs_to :content_item

  validates :content_item, presence: true, uniqueness: true
  validates :type, presence: true
  validates :explanation, presence: true, if: :withdrawal?
  validates :alternative_path, presence: true, if: :redirect?

  def withdrawal?
    type == "withdrawal"
  end

  def redirect?
    type == "redirect"
  end
end
