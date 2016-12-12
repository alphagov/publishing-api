class UnpublishingRedirectValidator < ActiveModel::Validator
  def validate(unpublishing)
    return unless unpublishing.content_item

    base_path = unpublishing.content_item.base_path

    if base_path == unpublishing.alternative_path
      unpublishing.errors.add(
        :alternative_path,
        "base_path matches the unpublishing alternative_path #{base_path}"
      )
    end
  end
end
