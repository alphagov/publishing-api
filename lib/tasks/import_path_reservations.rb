require "json"

module Tasks
  class ImportPathReservations
    def initialize(file:, total_lines:, stdout:, create_reservations: false)
      @file = file
      @total_lines = total_lines
      @stdout = stdout
      @create_reservations = create_reservations
    end

    def import_all
      file.each.with_index(1) do |json, index|
        parsed_json = JSON.parse(json).deep_symbolize_keys

        updated_at = parsed_json.fetch(:updated_at)
        created_at = parsed_json.fetch(:created_at)
        publishing_app = parsed_json.fetch(:publishing_app)
        base_path = parsed_json.fetch(:base_path)

        path_reservation = PathReservation.find_by(base_path: base_path)

        unless path_reservation
          puts
          puts "Will create path #{base_path}"

          if @create_reservations
            path_item = {
              publishing_app: publishing_app,
              base_path: base_path,
              created_at: created_at,
              updated_at: updated_at
            }

            response = EventLogger.log_command(Commands::ReservePath, path_item) do
              Commands::ReservePath.call(path_item)
            end

            puts response.code
          end
        end

        print_progress(index, total_lines)
      end

      stdout.puts
    end

  private

    attr_reader :file, :total_lines, :stdout, :draft

    def print_progress(completed, total)
      percent_complete = ((completed.to_f / total) * 100).round
      return if percent_complete == @percent_complete
      @percent_complete = percent_complete
      percent_remaining = 100 - percent_complete

      stdout.print "\r"
      stdout.flush
      stdout.print "Progress [#{"=" * percent_complete}>#{"." * percent_remaining}] (#{percent_complete}%)"
      stdout.flush
    end
  end
end
