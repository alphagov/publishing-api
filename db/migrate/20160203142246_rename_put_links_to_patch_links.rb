class RenamePutLinksToPatchLinks < ActiveRecord::Migration[4.2]
  class Event < ActiveRecord::Base
  end

  def change
    Event.where(action: "PutLinkSet").update_all(action: "PatchLinkSet")
  end
end
