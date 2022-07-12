class DebugController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @presenter = Presenters::DebugPresenter.new(params[:content_id])
  end

  def experiment
    mismatched_responses = Sidekiq.redis do |redis|
      redis.lrange("experiments:#{params[:experiment]}:mismatches", 0, -1)
    end

    @mismatched_responses = mismatched_responses.map do |json|
      parsed = Oj.load(json)

      missing, other = parsed.partition do |(operator, _, _)|
        operator == "-"
      end

      extra, changed = other.partition do |(operator, _, _)|
        operator == "+"
      end

      missing, extra = fix_ordering_issues(missing, extra)

      {
        missing:,
        extra:,
        changed:,
      }
    end
  end

private

  def fix_ordering_issues(missing, extra)
    duplicates = missing.map(&:last) & extra.map(&:last)

    missing = missing.reject { |(_, _, entry)| duplicates.include?(entry) }
    extra = extra.reject { |(_, _, entry)| duplicates.include?(entry) }

    [missing, extra]
  end
end
