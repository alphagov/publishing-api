# list queues
Sidekiq::Queue.all

# queue sizes
Sidekiq::Queue.all.map(&:count)
Sidekiq::Stats.new.queues

# created at time by digest key/ID
# https://github.com/mhenrixon/sidekiq-unique-jobs/blob/76aa8c947b8318ebbc5fa021be240097d7a926b3/lib/sidekiq_unique_jobs/digests.rb#L96
SidekiqUniqueJobs::Digests.new.entries
# via Sidekiq
Sidekiq.redis { it.zscan("uniquejobs:digests", match: "*", count: 1000).to_a }.to_h

# ... for digests with locked jobs
SidekiqUniqueJobs::Digests.new.entries.reject do |digest_id, _|
  SidekiqUniqueJobs::Lock.new(digest_id).locked_jids.empty?
end

# digest from its key/ID
SidekiqUniqueJobs::Digests.new("uniquejobs:7fd6118dc979f0376b72cb5b9291dc68")

# lock from digest key/ID
SidekiqUniqueJobs::Lock.new("uniquejobs:7fd6118dc979f0376b72cb5b9291dc68")

# locks by digest key/ID
# could we use the whole digest and pass in the score as the time to the lock if
# we're missing the time in the locks?
# https://github.com/mhenrixon/sidekiq-unique-jobs/blob/76aa8c947b8318ebbc5fa021be240097d7a926b3/lib/sidekiq_unique_jobs/digests.rb#L96
# it seems like you sometimes get the time for free with a lock but sometimes it
# needs to come from the digest
SidekiqUniqueJobs::Digests.new.entries.keys.each_with_object({}) do |digest_id, acc|
  lock = SidekiqUniqueJobs::Lock.new(digest_id)
  acc[digest_id] = lock unless lock.locked_jids.empty?
end

# locked job ids from digest key/ID
SidekiqUniqueJobs::Lock.new("uniquejobs:7fd6118dc979f0376b72cb5b9291dc68").locked_jids
# I think this too
# https://github.com/mhenrixon/sidekiq-unique-jobs/blob/76aa8c947b8318ebbc5fa021be240097d7a926b3/lib/sidekiq_unique_jobs/orphans/reaper.rb#L87-L90
# https://redis.io/docs/latest/commands/hkeys
Sidekiq.redis { it.call("HKEYS", "uniquejobs:40e09a31f8d6c4cdc793bc8b147b631e:LOCKED") }
# or
Sidekiq.redis { it.hkeys("uniquejobs:40e09a31f8d6c4cdc793bc8b147b631e:LOCKED") }
# and
# https://github.com/mhenrixon/sidekiq-unique-jobs/blob/76aa8c947b8318ebbc5fa021be240097d7a926b3/lib/sidekiq_unique_jobs/lock.rb#L121-L123
SidekiqUniqueJobs::Redis::Hash.new("uniquejobs:40e09a31f8d6c4cdc793bc8b147b631e:LOCKED")

# locked job IDs by digest key/ID
SidekiqUniqueJobs::Digests.new.entries.keys.each_with_object({}) do |digest_id, acc|
  locked_jids = SidekiqUniqueJobs::Lock.new(digest_id).locked_jids
  acc[digest_id] = locked_jids unless locked_jids.empty?
end

# I think: created at time by job ID from digest key/ID (but this might actually
# just be the time the digest was created - I'm unsure about whether it can be
# different)
SidekiqUniqueJobs::Redis::Hash
  .new("uniquejobs:40e09a31f8d6c4cdc793bc8b147b631e:LOCKED")
  .entries(with_values: true)
# or
Sidekiq.redis { it.hgetall("uniquejobs:40e09a31f8d6c4cdc793bc8b147b631e:LOCKED") }

# check a lock's TTL (-2 = expired, positive = time to expiry)
Sidekiq.redis { it.ttl("uniquejobs:b6a25b38fea951818c7e4ced83bc9993:LOCKED") }

# find examples where the digest created at as reported by the entries method
# differs from the job's created at recorded in Redis - NO EXAMPLES, which
# probably means that jobs are always in sync with their digest/lock
SidekiqUniqueJobs::Digests.new.entries.reject do |key, digest_created_at|
  Sidekiq.redis {
    it.hgetall("#{key}:LOCKED")
  }.values.all? do |job_redis_created_at|
    job_redis_created_at.to_d == digest_created_at.to_d
  end
end

# find examples where the locked jobs reported by the lock for a digest differ
# from those found when querying Redis directly - NO EXAMPLES, which probably
# means SidekiqUniqueJobs isn't caching old values
SidekiqUniqueJobs::Digests.new.entries.keys.reject do |key|
  digest_locked_jids = SidekiqUniqueJobs::Lock.new(key).locked_jids
  redis_job_ids = Sidekiq.redis { it.hkeys("#{key}:LOCKED") }

  digest_locked_jids == redis_job_ids
end

# find locks that should have expired
expiry_window_end = Time.zone.now - SidekiqUniqueJobs.config.lock_ttl.seconds

SidekiqUniqueJobs::Digests.new.entries.map { |digest_id, created_at|
  created_at_time = Time.zone.at(created_at.to_f)

  # less than an hour old
  next if created_at_time > expiry_window_end
  # has jobs attached
  next unless SidekiqUniqueJobs::Lock.new(digest_id).locked_jids.empty?

  { digest_id:, created_at: created_at_time.to_s }
}.compact

# SidekiqUniqueJobs 8.x method for getting orphans to be reaped
Sidekiq.redis { SidekiqUniqueJobs::Orphans::RubyReaper.new(it).orphans }

# work out why they're unreaped (ignoring TTL)
reaper = Sidekiq.redis { SidekiqUniqueJobs::Orphans::RubyReaper.new(it) }
breakdown = { active: [], enqueued: [], retried: [], scheduled: [], unknown: [] }
SidekiqUniqueJobs::Digests.new.entries.keys.each_with_object({}) do |digest_id, _acc|
  # TODO: consider skipping where the created_at is too recent to be reaped (see
  # Rake task)
  key = if reaper.active?(digest_id)
          :active
        elsif reaper.enqueued?(digest_id)
          :enqueued
        elsif reaper.retried?(digest_id)
          :retried
        elsif reaper.scheduled?(digest_id)
          :scheduled
        else
          :unknown
        end

  breakdown[key].push(digest_id)
end
puts breakdown.inspect
puts breakdown.transform_values(&:length).inspect

# it looks like these are almost all in the retry set: check the retry set via
# Sidekiq
Sidekiq::RetrySet.new.to_a
# this has some useful fields. I think created at here must be when it was added
# to the retry set since it's later than the score. some of the fields in the
# item are also available in the entry
Sidekiq::RetrySet.new.first.score
Sidekiq::RetrySet.new.first.item.slice(%w[
  queue
  class
  args
  jid
  created_at
  baggage
  trace_propagation_headers
  lock_ttl
  lock_args
  lock_digest
  enqueued_at
  error_message
  error_class
  failed_at
  retry_count
  retried_at
])

# check if a specific digest is in the retry set (per SidekiqUniqueJobs)
Sidekiq.redis { it.zscan("uniquejobs:digests", match: "*uniquejobs:b6a25b38fea951818c7e4ced83bc9993*", count: 1).to_a.any? }
