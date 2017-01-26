class UnpublishingRedirectValidator < ActiveModel::Validator
  def validate(unpublishing)
    return unless unpublishing.edition

    base_path = unpublishing.edition.base_path

    if base_path == unpublishing.alternative_path
      unpublishing.errors.add(
        :alternative_path,
        "base_path matches the unpublishing alternative_path #{base_path}"
      )
    end
  end
end
