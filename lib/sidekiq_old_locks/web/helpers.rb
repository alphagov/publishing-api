module SidekiqOldLocks
  module Web
    module Helpers
      def old_digests
        SidekiqUniqueJobs::Digests.new.entries.map { |digest, created_at|
          created_at_float = created_at.to_f
          created_at_time = Time.zone.at(created_at_float)

          next if created_at_time > expiry_window_end

          { digest:, created_at: created_at_float, state: state(digest) }
        }
          .compact
          .sort_by { -it[:created_at] }
      end

    private

      def expiry_window_end
        @expiry_window_end ||= Time.zone.now - SidekiqUniqueJobs.config.lock_ttl.seconds
      end

      def state(digest)
        @reaper ||= Sidekiq.redis { SidekiqUniqueJobs::Orphans::RubyReaper.new(it) }

        if @reaper.active?(digest)
          :active
        elsif @reaper.enqueued?(digest)
          :enqueued
        elsif @reaper.retried?(digest)
          :retried
        elsif @reaper.scheduled?(digest)
          :scheduled
        else
          :unknown
        end
      end
    end
  end
end
