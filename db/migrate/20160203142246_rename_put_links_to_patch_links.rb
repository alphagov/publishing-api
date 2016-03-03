class RenamePutLinksToPatchLinks < ActiveRecord::Migration
  class Event < ActiveRecord::Base
  end

  def change
    Event.where(action: 'PutLinkSet').update_all(action: 'PatchLinkSet')
  end
end
