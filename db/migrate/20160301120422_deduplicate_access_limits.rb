class DeduplicateAccessLimits < ActiveRecord::Migration
  def change
    DataHygiene::AccessLimitsCleaner.cleanup
  end
end
