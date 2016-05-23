class Linkable < ActiveRecord::Base
  belongs_to :content_item

  validates :base_path, presence: true, uniqueness: true
  validates :state, presence: true
  validates :content_item, presence: true
  validates :document_type, presence: true
end
