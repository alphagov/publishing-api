module Queries
  module ArelHelpers
    def get_rows(scope)
      scope = scope.to_sql unless scope.is_a? String
      result = ActiveRecord::Base.connection.exec_query(scope)

      result.to_hash.map do |r|
        r.each do |k, v|
          case result.column_types[k]
          when ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Json
            r[k] = Oj.load(v) if v
          when ActiveRecord::ConnectionAdapters::PostgreSQL::OID::DateTime
            r[k] = Time.zone.parse(v).iso8601 if v
          end
        end
      end
    end
  end
end
