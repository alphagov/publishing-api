module Presenters
  module ContentItemPresenter
    def self.present(content_item_hash)
      metadata = content_item_hash.fetch(:metadata)
      public_updated_at = content_item_hash.fetch(:public_updated_at).iso8601

      content_item_hash
        .except(:metadata, :id, :version)
        .merge(metadata)
        .merge(public_updated_at: public_updated_at)
    end
  end
end
