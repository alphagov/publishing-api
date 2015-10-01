module Replaceable
  extend ActiveSupport::Concern

  class_methods do
    def create_or_replace(payload)
      item = self.lock.find_or_initialize_by(content_id: payload[:content_id], locale: payload[:locale])
      if block_given?
        yield(item)
      end
      item.assign_attributes(
        self.column_defaults.merge(payload).merge(
          version: increment_version(item.version),
          id: item.id
        )
      )
      item.save!
    end

    private

    def increment_version(version)
      (version.presence || 0) + 1
    end
  end
end
