class LinkSet < ApplicationRecord
  include FindOrCreateLocked

  has_many :links, -> { order(link_type: :asc, position: :asc) }, dependent: :destroy

  after_save do
    lock_version = LockVersion.find_or_create_by(target: self)
    lock_version.update! number: stale_lock_version
  end
end
