class LinkSet < ActiveRecord::Base
  has_many :links, -> { order(id: :asc) }, dependent: :destroy
end
