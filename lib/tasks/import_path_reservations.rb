require "json"

module Tasks
  class ImportPathReservations
    def initialize(file:, total_lines:, stdout:)
      @file = file
      @total_lines = total_lines
      @stdout = stdout
    end

    def import_all
      PathReservation.delete_all

      file.each.with_index(1) do |json, index|
        parsed_json = JSON.parse(json).deep_symbolize_keys

        updated_at = parsed_json.fetch(:updated_at)
        created_at = parsed_json.fetch(:created_at)
        publishing_app = parsed_json.fetch(:publishing_app)
        path = parsed_json.fetch(:path)

        PathReservation.create!(
          publishing_app: publishing_app,
          base_path: path,
          created_at: created_at,
          updated_at: updated_at,
        )

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
