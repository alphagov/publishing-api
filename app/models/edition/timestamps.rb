class Edition::Timetamps
  def self.edited(
    edition,
    payload,
    previous_live_version = nil,
    now = Time.zone.now
  )
    edition.last_edited_at = payload[:last_edited_at] || now
    edition.temporary_last_edited_at = now
    edition.publisher_last_edited_at = payload[:last_edited_at]

    edition.first_published_at = payload[:first_published_at] || previous_live_version.first_published_at
    # When we have no previous live version we can set this as current time
    # (as first time published to draft)
    # Otherwise we can only copy a temporary date to avoid accidentally adding
    # magicly created data
    edition.temporary_first_published_at = if previous_live_version
      previous_live_version.temporary_first_published_at
    else
      now
    end
    edition.publisher_first_published_at = payload[:first_published_at]

    edition.public_updated_at = payload[:public_updated_at]
    edition.temporary_major_published_at = if edition.update_type == "major"
      now
    else
      previous_live_version.temporary_major_published_at
    end
    edition.publisher_major_published_at = payload[:public_updated_at]

    edition.temporary_published_at = now
    edition.publisher_published_at = nil

    edition.save!
  end

  def self.live_transition(
    edition,
    previous_live_version = nil,
    specified_update_type = nil,
    now = Time.zone.now
  )
    edition.first_published_at = now unless edition.first_published_at
    edition.temporary_first_published_at = if previous_live_version
      previous_live_version.first_published_at
    else
      now
    end

    major_update_type = (edition.update_type || specified_update_type) == "major"

    # This field is a bit complicated as it should only be set on a major update
    # type but if there are no majors then we have to set it to a time as no
    # time for this causes problems.
    unless edition.public_updated_at
      if major_update_type || !previous_live_version
        edition.public_updated_at = now
      else
        edition.public_updated_at = previous_live_version.public_updated_at
      end
    end

    edition.temporary_major_published_at = if major_update_type
      now
    else
      previous_live_version.temporary_major_published_at
    end

    edition.temporary_published_at = now

    edition.save!
  end
end
