module Types
  class ContentApiDatetime < Types::BaseScalar
    def self.coerce_input(input_value, _context)
      # N/A
    end

    def self.coerce_result(ruby_value, _context)
      ruby_value.in_time_zone("Europe/London").iso8601
    end
  end
end
