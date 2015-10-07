module Replaceable
  extend ActiveSupport::Concern

  included do
    def assign_attributes_with_defaults(attributes)
      new_attributes = self.class.column_defaults.symbolize_keys.except(:id)
        .merge(attributes)
        .merge(attribute_overrides)
        .merge(attributes.symbolize_keys)
      assign_attributes(new_attributes)
    end

  private
    def attribute_overrides
      {
        version: increment_version,
      }
    end

    def increment_version
      (self.version || 0) + 1
    end
  end

  class_methods do
    def create_or_replace(payload, &block)
      item = self.lock.find_or_initialize_by(payload.slice(*self.query_keys))
      if block_given?
        yield(item)
      end
      item.assign_attributes_with_defaults(payload.except("id"))

      retry_strategy = if item.new_record?
        method(:retrying_on_unique_constraint_violation)
      else
        method(:without_retry)
      end

      retry_strategy.call { item.save! }

      item
    end

    def retrying_on_unique_constraint_violation(&block)
      yield
    rescue ActiveRecord::RecordNotUnique => e
      raise Command::Retry.new("Race condition in create_or_replace, retrying (original error: '#{e.message}')")
    end

    def without_retry(&block)
      yield
    end
  end
end
