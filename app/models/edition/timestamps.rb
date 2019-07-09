class Edition::Timestamps
  def self.edited(
    edition,
    payload,
    previous_live_version = nil,
    now = Time.zone.now
  )
    edition.temporary_last_edited_at = now
    edition.publisher_last_edited_at = payload[:last_edited_at]
    edition.last_edited_at = payload[:last_edited_at] || now

    # first_published_at should eventually be associated with a document model,
    # therefore avoiding the need to copy between editions as this is fragile
    edition.temporary_first_published_at = previous_live_version&.temporary_first_published_at
    edition.publisher_first_published_at = payload[:first_published_at] ||
      previous_live_version&.publisher_first_published_at
    edition.first_published_at = payload[:first_published_at] ||
      previous_live_version&.first_published_at

    # We set this on non-major updates so that editions can maintain their value
    # from previous items. In future we'd like to avoid this date being copied
    # and instead have a reference between an edition and it's previous
    # major publishing.
    if edition.update_type == "major"
      edition.major_published_at = nil
    else
      edition.major_published_at = previous_live_version&.major_published_at
    end

    # In time we'd like to rename public_updated_at to major_published_at as
    # part of the payload, but in the meantime we are populating the field
    # with the optionally provided public_updated_at field.
    edition.publisher_major_published_at = payload[:public_updated_at]

    # If the payload value is nil, we rely on publish to populate public_updated_at
    edition.public_updated_at = payload[:public_updated_at]

    # populate transitory timestamps
    edition.publishing_api_first_published_at = edition.temporary_first_published_at
    edition.publishing_api_last_edited_at = edition.temporary_last_edited_at

    edition.save!
  end

  def self.live_transition(
    edition,
    update_type,
    previous_live_version = nil,
    now = Time.zone.now
  )
    # We set this because a lack of temporary_first_published_at indicates the
    # edition has not been published
    unless edition.temporary_first_published_at.present?
      edition.temporary_first_published_at = now
    end

    unless edition.first_published_at.present?
      edition.first_published_at = now
    end

    edition.published_at = now

    if update_type == "major"
      edition.major_published_at = now
      edition.public_updated_at = now unless edition.public_updated_at.present?
    else
      # We copy major_published_at here as well as in put content as it's
      # possible for someone to specify the update_type at publish time.
      # Once update_type is no longer an option for publish this need only be
      # sent in put content.
      edition.major_published_at = previous_live_version&.major_published_at
      unless edition.public_updated_at.present?
        # Although we expect the update_type of the first edition to be major,
        # this isn't always the case, so we fall back to now if the previous item
        # isn't available.
        edition.public_updated_at = previous_live_version&.public_updated_at || now
      end
    end

    # populate transitory timestamps
    edition.publishing_api_first_published_at = edition.temporary_first_published_at

    edition.save!
  end
end
