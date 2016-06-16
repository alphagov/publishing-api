class ExperimentResult
  def initialize(name, id, type, redis, run_output = nil, duration = nil)
    @name = name
    @key = "#{name}:#{id}"
    @redis = redis
    @type = type
    @run_output = run_output
    @duration = duration

    if (run_output.blank? || duration.blank?) && data_from_redis
      @run_output ||= data_from_redis.fetch(:run_output)
      @duration ||= data_from_redis.fetch(:duration)
    end
  end

  attr_reader :key, :run_output, :duration

  def store_run_output
    redis.set("experiments:#{key}:#{type}", {
      run_output: run_output,
      duration: duration,
    }.to_json)
  end

  def process_run_output(candidate)
    variation = HashDiff.diff(self.run_output, candidate.run_output)
    report_data(variation, candidate)
  end

  def control?
    type == :control
  end

  def candidate?
    type == :candidate
  end

  def available?
    run_output.present? && duration.present?
  end

private

  attr_reader :redis, :type, :name

  def data_from_redis
    redis_data = redis.get("experiments:#{key}:#{type}")

    if redis_data.present?
      JSON.parse(redis_data).deep_symbolize_keys
    end
  end

  def report_data(variation, candidate)
    statsd.timing("experiments.#{name}.control", self.duration)
    statsd.timing("experiments.#{name}.candidate", candidate.duration)

    if variation != []
      statsd.increment("experiments.#{name}.mismatches")
      redis.rpush("experiments:#{name}:mismatches", variation.to_json)
    end
  end

  def statsd
    PublishingAPI.service(:statsd)
  end
end
