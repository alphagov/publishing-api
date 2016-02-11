class LinkSet < ActiveRecord::Base
  has_many :links, dependent: :destroy
end
