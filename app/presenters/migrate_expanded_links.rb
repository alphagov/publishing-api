module Presenters
  module MigrateExpandedLinks
    extend self

    def document_types
      %w(service_manual_topic service_manual_guide)
    end
  end
end
