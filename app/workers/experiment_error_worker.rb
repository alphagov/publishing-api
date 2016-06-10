class ExperimentErrorWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :experiments

  def perform(name, id, exception_string)
    @name = name
    @scoped_id = "#{name}:#{id}"
    @result = result
    @duration = duration
    @type = type

    Sidekiq.redis do |redis|
      PublishingAPI.service(:statsd).increment("experiments.#{name}.exceptions")
      redis.rpush("#{name}:exceptions", exception_string)
    end
  ensure
    Sidekiq.redis do |redis|
      redis.unlock("name:id")
    end
  end
end
