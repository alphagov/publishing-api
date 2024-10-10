class ContentIdAlias < ApplicationRecord
  validates :name, uniqueness: true, presence: true
end
