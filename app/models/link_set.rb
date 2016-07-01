class LinkSet < ApplicationRecord
  has_many :links, -> { order(link_type: :asc, position: :asc) }, dependent: :destroy
end
