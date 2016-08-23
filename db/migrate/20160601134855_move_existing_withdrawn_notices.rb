class MoveExistingWithdrawnNotices < ActiveRecord::Migration
  def change
    # As of 2016-08-23 this code that was in this migration will no longer work
    # as it relied on the PresentedContentStoreWorker class which no longer
    # exists.
  end
end
