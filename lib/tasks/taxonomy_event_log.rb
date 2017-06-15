class TaxonomyEventLog
  def export
    exported = []
    previous_events = {}

    raw_events.each do |event|
      previous_taxons = previous_events[event.content_id].to_a
      current_taxons = event.payload[:links][:taxons]

      # Nil means that this `PatchLinkSet` doesn't change the `taxons` (which is
      # different from sending an empty array)
      next if current_taxons.nil?
      edition = fetch_edition(event.content_id)

      # It is possible for documents to not have an edition. This happens
      # when they are created as drafts, never published and then discarded.
      next unless edition

      (current_taxons - previous_taxons).each do |taxon_id|
        exported << build_line(event, edition, taxon_id, 1)
      end

      (previous_taxons - current_taxons).each do |taxon_id|
        exported << build_line(event, edition, taxon_id, -1)
      end

      previous_events[event.content_id] = current_taxons
    end

    exported.compact
  end

  def build_line(event, edition, taxon_id, change)
    supertype = GovukDocumentTypes.supertypes(document_type: edition.document_type)["navigation_document_supertype"]
    taxon = fetch_edition(taxon_id)
    return unless taxon

    {
      taggable_content_id: event.content_id,
      taggable_title: edition.title,
      taggable_navigation_document_supertype: supertype,
      taggable_base_path: edition.base_path,
      tagged_at: event.created_at,
      tagged_on: event.created_at.to_date,
      user_uid: event.user_uid,
      taxon_content_id: taxon_id,
      taxon_title: taxon.title,
      change: change,
    }
  end

private

  def fetch_edition(content_id)
    @edition_cache ||= {}

    @edition_cache[content_id] ||= begin
      document = Document.find_by(content_id: content_id) || return
      document.editions.last
    end
  end

  def raw_events
    Event
      .where("payload IS NOT NULL")
      .where(action: "PatchLinkSet")
      .order("id ASC")
  end
end
