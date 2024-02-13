class ContentItem < ApplicationRecord
  scope :draft, -> { where(content_store: "draft") }
  scope :live, -> { where(content_store: "live") }

  def register_routes(previous_item: nil)
    return unless should_register_routes?(previous_item:)

    tries = Rails.application.config.register_router_retries
    begin
      route_set.register!
    rescue GdsApi::BaseError
      tries -= 1
      tries.positive? ? retry : raise
    end
  end

  def delete_routes
    return unless should_register_routes?

    route_set.delete!
  end

  def route_set
    @route_set ||= RouteSet.from_content_item(self)
  end

private

  def should_register_routes?(previous_item: nil)
    return previous_item.route_set != route_set if previous_item

    true
  end

  def self.scheduled_publication_details(log_entry)
    return {} unless log_entry

    {
      publishing_scheduled_at: log_entry.scheduled_publication_time,
      scheduled_publishing_delay_seconds: log_entry.delay_in_milliseconds / 1000,
    }
  end

  private_class_method :scheduled_publication_details
end