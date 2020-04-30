class DistributedLock
  attr_reader :name, :timeout_seconds, :has_run

  def self.lock(name, timeout_seconds: 30, &block)
    new(name, timeout_seconds: timeout_seconds).run(&block)
  end

  def initialize(name, timeout_seconds:)
    @name = name
    @timeout_seconds = timeout_seconds
    @has_run = false
  end

  def run
    @has_run = false
    # Run this inside a transaction so lock can be automatically released
    # when tranasction completes - seems a less deadlock prone situation than
    # creating a lock and the releasing it later
    result = ActiveRecord::Base.transaction do
      ActiveRecord::Base.with_advisory_lock(
        name,
        timeout_seconds: timeout_seconds,
        transaction: true,
      ) do
        @has_run = true
        yield
      end
    end

    raise FailedToAcquireLock unless @has_run

    result
  end

  class FailedToAcquireLock < StandardError; end
end
