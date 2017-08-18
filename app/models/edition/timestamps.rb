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

    edition.save!
  end
end
