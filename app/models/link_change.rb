class LinkChange < ApplicationRecord
  belongs_to :action
  enum :change, add: 1, remove: -1
end
