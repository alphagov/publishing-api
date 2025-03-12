class RemoveOldEventsJob
  include Sidekiq::Job

  def perform
    Event.where("created_at < ?", 30.days.ago).destroy_all
  end
end
