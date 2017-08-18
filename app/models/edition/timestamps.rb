class Edition::Timestamps
  def self.edited(
    edition,
    payload,
    previous_live_version = nil,
    now = Time.zone.now
  )
    # first_published_at should eventually be associated with a document model,
    # therefore avoiding the need to copy between editions as this is fragile
    edition.temporary_first_published_at = previous_live_version&.temporary_first_published_at
    edition.publisher_first_published_at = payload[:first_published_at]

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

    edition.save!
  end

  def self.live_transition(
    edition,
    previous_live_version = nil,
    now = Time.zone.now
  )
    # We set this because a lack of temporary_first_published_at indicates the
    # edition has not been published
    unless edition.temporary_first_published_at.present?
      edition.temporary_first_published_at = now
    end

    if edition.update_type == "major"
      edition.major_published_at = now
    else
      # We copy major_published_at here as well as in put content as it's
      # possible for someone to specify the update_type at publish time.
      # Once update_type is no longer an option for publish this need only be
      # sent in put content.
      edition.major_published_at = previous_live_version&.major_published_at
    end

    edition.save!
  end
end
