class LinkSet < ApplicationRecord
  include FindOrCreateLocked

  has_many :links, -> { order(link_type: :asc, position: :asc) }, dependent: :destroy
end
