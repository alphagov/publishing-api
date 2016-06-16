class ExperimentResult
  def initialize(name, id, type, redis, run_output = nil, duration = nil)
    @name = name
    @key = "#{name}:#{id}"
    @redis = redis
    @type = type
    @run_output = run_output
    @duration = duration

    if run_output.blank? || duration.blank?
      redis_data = data_from_redis

      if redis_data
        @run_output ||= redis_data.fetch(:run_output)
        @duration ||= redis_data.fetch(:duration)
      end
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
    variation = HashDiff.diff(sort(self.run_output), sort(candidate.run_output))
    report_data(variation, candidate)
    redis.del("experiments:#{key}:candidate")
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

  def sort(object)
    case object
    when Array
      object.sort_by(&:object_id)
    when Hash
      object.each_with_object({}) { |(key, value), hash|
        hash[key] = sort(value)
      }
    else
      object
    end
  end
end
