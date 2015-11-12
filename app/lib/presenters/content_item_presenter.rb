module Presenters
  module ContentItemPresenter
    def self.present(content_item_hash)
      content_item_hash = content_item_hash
                            .except(:id, :version, :update_type)

      if content_item_hash[:public_updated_at].present?
        content_item_hash.merge(
          public_updated_at: content_item_hash[:public_updated_at].iso8601
        )
      else
        content_item_hash
      end
    end
  end
end
