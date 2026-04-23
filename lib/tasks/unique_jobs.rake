namespace :unique_jobs do
  desc "Alerts about jobless digests that should have been reaped"
  task audit: :environment do
    # technically if there are more than 1000 locks when the reaper runs, the
    # minimum_unreaped_time could be earlier, because it would take several runs
    # to reap them all (the interval between runs is 10 minutes)
    # TODO: consider more aggressive reaping?
    minimum_unreaped_time = Time.zone.now -
      SidekiqUniqueJobs.config.lock_ttl.seconds -
      SidekiqUniqueJobs.config.reaper_interval.seconds -
      SidekiqUniqueJobs.config.reaper_timeout.seconds

    orphaned_digests = SidekiqUniqueJobs::Digests.new.entries.map { |digest_id, created_at|
      created_at_time = Time.zone.at(created_at.to_f)

      next if created_at_time > minimum_unreaped_time
      # TODO: use correct orphan check?
      # https://github.com/mhenrixon/sidekiq-unique-jobs/blob/4e57de89f3ac817b876c6b5d57050e05accad2d6/lib/sidekiq_unique_jobs/orphans/ruby_reaper.rb#L157-L169
      next unless SidekiqUniqueJobs::Lock.new(digest_id).locked_jids.empty?

      { digest_id:, created_at: created_at_time.to_s }
    }.compact

    unless orphaned_digests.empty?
      GovukError.notify(
        "Digests found past time to live and with no jobs",
        level: "warning",
        extra: { orphaned_digests: },
      )
    end
  end
end
