module Presenters
  module ContentItemPresenter
    def self.present(content_item_hash)
      public_updated_at = content_item_hash.fetch(:public_updated_at).iso8601

      content_item_hash
        .except(:id, :version, :update_type)
        .merge(public_updated_at: public_updated_at)
    end
  end
end
