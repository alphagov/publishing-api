module Commands
  class UnreservePath < BaseCommand
    def call
      reservation = lookup_reservation
      check_is_owned_by_app(reservation)
      reservation.destroy!
      Success.new(payload)
    end

  private

    def lookup_reservation
      PathReservation.find_by!(
        base_path: payload[:base_path],
      )
    rescue ActiveRecord::RecordNotFound
      msg = "#{payload[:base_path]} is not reserved"
      raise CommandError.new(code: 404, message: msg)
    end

    def check_is_owned_by_app(reservation)
      publishing_app = payload[:publishing_app]
      base_path = payload[:base_path]
      return if reservation.publishing_app == publishing_app

      msg = "#{base_path} is reserved by #{reservation.publishing_app}"
      raise CommandError.new(code: 422, message: msg)
    end
  end
end
