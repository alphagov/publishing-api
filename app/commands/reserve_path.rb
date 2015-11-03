module Commands
  class ReservePath < BaseCommand
    def call
      PathReservation.reserve_base_path!(base_path, payload[:publishing_app])
      Success.new(payload)
    end
  end
end
