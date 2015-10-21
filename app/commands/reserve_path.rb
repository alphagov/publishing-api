module Commands
  class ReservePath < BaseCommand
    def call
      Adapters::UrlArbiter.call(base_path, payload[:publishing_app])
      PathReservation.reserve_base_path!(base_path, payload[:publishing_app])
      Success.new(payload)
    end
  end
end
