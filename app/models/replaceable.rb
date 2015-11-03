module Replaceable
  extend ActiveSupport::Concern

  class_methods do
    def create_or_replace(payload, &block)
      payload = payload.deep_symbolize_keys

      item = self.lock.find_or_initialize_by(payload.slice(*self.query_keys))

      retry_strategy = if item.new_record?
        method(:retrying_on_unique_constraint_violation)
      else
        method(:without_retry)
      end

      retry_strategy.call do
        item.assign_attributes(payload.except(:id, :version))

        if block_given?
          yield(item)
        end

        item.save! if item.changed?
      end

      item
    end

    def retrying_on_unique_constraint_violation(&block)
      yield
    rescue ActiveRecord::RecordNotUnique => e
      raise CommandRetryableError.new("Race condition in create_or_replace, retrying (original error: '#{e.message}')")
    end

    def without_retry(&block)
      yield
    end
  end
end
