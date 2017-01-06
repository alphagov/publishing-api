module Queries
  module GetLatest
    class << self
      def call(content_item_scope)
        content_item_scope.where(id: inner_scope(content_item_scope))
      end

      def inner_scope(content_item_scope)
        content_item_scope
          .order(:document_id, user_facing_version: :desc)
          .select("distinct on(editions.document_id) editions.document_id, editions.id")
          .map(&:id)
      end
    end
  end
end
