module Commands
  class ReservePath < BaseCommand
    def call
      PathReservation.reserve_base_path!(
        base_path,
        payload[:publishing_app],
        override_existing: payload.fetch(:override_existing, false),
      )
      Success.new(payload)
    end

  private

    def base_path
      payload.fetch(:base_path)
    end
  end
end
