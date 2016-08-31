module Queries
  module ArelHelpers
    CTE = Struct.new(:table, :compiled_scope)

    def table(table)
      Arel::Table.new(table, ActiveRecord::Base)
    end

    # Creates a CTE (common table expression, or `WITH` query)
    # from an Arel scope and returns a `CTE` struct wrapping two references to the CTE.
    # A CTE is an alternative to a subquery, it defines a temporary virtual table
    # for just a single query. See:
    # https://www.postgresql.org/docs/9.3/static/queries-with.html
    # https://github.com/rails/arel#complex-joins
    #
    # `CTE#table` is a reference to a virtual Arel::Table that has
    # column accessors and can be used in `.join()` statements
    # `CTE#compiled_scope` should be passed to the `with` statement
    # when you want to use the CTE.
    def cte(scope, as:)
      table = Arel::Table.new(as.to_s)
      compiled_scope = Arel::Nodes::As.new(table, scope)
      CTE.new(table, compiled_scope)
    end

    def get_column(scope)
      ActiveRecord::Base.connection.exec_query(scope).map(&:values).flatten
    end

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
