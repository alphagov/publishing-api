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

      def old_digest_retry_set_data(digest)
        Sidekiq::RetrySet.new.entries.map { |entry|
          next unless entry.item["lock_digest"] == digest

          {
            jid: entry.item["jid"],
            created_at: pretty_time(entry.item["created_at"]),
            failed_at: pretty_time(entry.item["failed_at"]),
            enqueued_at: pretty_time(entry.item["enqueued_at"]),
            retried_at: pretty_time(entry.item["retried_at"]),
            retry_count: entry.item["retry_count"],
            queue: entry.item["queue"],
            class: entry.item["class"],
            lock_args: JSON.pretty_generate(entry.item["lock_args"]),
            args: JSON.pretty_generate(entry.item["args"]),
            lock_ttl: entry.item["lock_ttl"],
            error_class: entry.item["error_class"],
            error_message: entry.item["error_message"],
          }
        }.compact
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

      def pretty_time(epoch_time)
        Time.zone.at(epoch_time.to_f).to_s
      end
    end
  end
end
