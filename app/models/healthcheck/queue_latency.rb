class Healthcheck::QueueLatency < GovukHealthcheck::SidekiqQueueLatencyCheck
  QUEUES = {
    "downstream_high" => {
      warning: 45, # seconds
      critical: 90, # seconds
    },
  }.freeze

  def warning_threshold(queue:)
    QUEUES.dig(queue, :warning) || Float::INFINITY
  end

  def critical_threshold(queue:)
    QUEUES.dig(queue, :critical) || Float::INFINITY
  end
end
