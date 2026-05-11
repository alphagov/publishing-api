# Useful recipes for investigating issues with Sidekiq

This document provides various code snippets for looking into locks/digests in
Sidekiq/SidekiqUniqueJobs. They might prove useful when investigating suspected
issues with the publishing queue (e.g. when updates to a document are failing).

These recipes were initially developed when working on adding the [old locks][]
'tab' to the Sidekiq web UI, which might also prove useful (as well as the
[helper code][] that powers it). To see the Sidekiq web UI in Publishing API,
you'll first need to set up [port forwarding][].

[helper code]: https://github.com/alphagov/publishing-api/blob/main/lib/sidekiq_old_locks/web/helpers.rb
[old locks]: http://localhost:8080/sidekiq/old_locks
[port forwarding]: https://docs.publishing.service.gov.uk/repos/publishing-api/admin-tasks.html#viewing-the-sidekiq-ui

## Digests and their creation time

```rb
# using SidekiqUniqueJobs
SidekiqUniqueJobs::Digests.new.entries

# using Sidekiq
Sidekiq.redis { it.zscan("uniquejobs:digests", match: "*", count: 1000).to_a }.to_h
```

## Digests ready to be reaped

This uses the SidekiqUniqueJobs v8 API. The API changes in v9.

```rb
Sidekiq.redis { SidekiqUniqueJobs::Orphans::RubyReaper.new(it).orphans }
```

## Digest and lock information

```rb
digest = "uniquejobs:7fd6118dc979f0376b72cb5b9291dc68"

SidekiqUniqueJobs::Digests.new(digest)
SidekiqUniqueJobs::Lock.new(digest)
```

### Locked job IDs

```rb
digest = "uniquejobs:7fd6118dc979f0376b72cb5b9291dc68"

# using SidekiqUniqueJobs
SidekiqUniqueJobs::Lock.new(digest).locked_jids
SidekiqUniqueJobs::Redis::Hash.new(digest)

# using Sidekiq
Sidekiq.redis { it.hkeys("#{digest}:LOCKED") }
Sidekiq.redis { it.call("HKEYS", "#{digest}:LOCKED") }
```

### Creation time by job

This is the time listed in Redis for the job but it's likely equivalent to the
digest creation time.

```rb
digest = "uniquejobs:7fd6118dc979f0376b72cb5b9291dc68"

# using SidekiqUniqueJobs
SidekiqUniqueJobs::Redis::Hash.new("#{digest}:LOCKED").entries(with_values: true)

# using Sidekiq
Sidekiq.redis { it.hgetall("#{digest}:LOCKED") }
```

### Lock TTL

`-2` seems to mean the lock is past TTL; positive values are the time until TTL.

```rb
digest = "uniquejobs:7fd6118dc979f0376b72cb5b9291dc68"

Sidekiq.redis { it.ttl("#{digest}:LOCKED") }
```

## Retry set

```rb
Sidekiq::RetrySet.new.entries
```

### Check if a digest is in the retry set

```rb
digest = "uniquejobs:7fd6118dc979f0376b72cb5b9291dc68"

Sidekiq.redis { it.zscan("uniquejobs:digests", match: "*#{digest}*", count: 1).to_a.any? }
```
