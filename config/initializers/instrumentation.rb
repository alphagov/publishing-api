statsd = Statsd.new
statsd.namespace = "govuk.app.publishing-api"

ActiveSupport::Notifications.subscribe("cache_read.active_support") do |_name, _start, _finish, _id, payload|
  hit_or_miss = payload[:hit] ? "cache_hit" : "cache_miss"
  statsd.increment("cache.#{hit_or_miss}", 1)
end
