# This is a monkey patch for a bug that is in Rails 5.0.0. When a JSON column
# in a database table is set to null it is incorrectly serialized to a string
# value of "null" rather than the underlying database format of NULL.
#
# This has already been merged into Rails: https://github.com/rails/rails/pull/25670
# and should be released for Rails 5.0.1
#
raise "Do we need still need to patch ActiveRecord JSON Support?" if Gem::Version.new(Rails.version) >= Gem::Version.new("5.0.1")

module ActiveRecord
  module Type
    module Internal
      class AbstractJson
        def serialize(value)
          if value.nil?
            nil
          else
            ::ActiveSupport::JSON.encode(value)
          end
        end
      end
    end
  end
end
