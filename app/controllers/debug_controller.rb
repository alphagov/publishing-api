class DebugController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @presenter = Presenters::DebugPresenter.new(params[:content_id])
  end

  def experiment
    mismatched_responses = Sidekiq.redis { |redis|
      redis.lrange("experiments:#{params[:experiment]}:mismatches", 0, -1)
    }

    @mismatched_responses = mismatched_responses.map { |json|
      parsed = Oj.load(json)

      missing, other = parsed.partition {|(operator, _, _)|
        operator == "-"
      }

      extra, changed = other.partition {|(operator, _, _)|
        operator == "+"
      }

      missing, extra = fix_ordering_issues(missing, extra)

      {
        missing: missing,
        extra: extra,
        changed: changed,
      }
    }
  end

private

  def fix_ordering_issues(missing, extra)
    duplicates = missing.map(&:last) & extra.map(&:last)

    missing = missing.reject { |(_, _, entry)| duplicates.include?(entry) }
    extra = extra.reject { |(_, _, entry)| duplicates.include?(entry) }

    [missing, extra]
  end
end
