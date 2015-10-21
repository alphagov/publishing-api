class Version < ActiveRecord::Base
  belongs_to :target, polymorphic: true

  def increment
    self.number += 1
  end

  def copy_version_from(target)
    version = Version.find_by!(target: target)
    self.number = version.number
  end
end
