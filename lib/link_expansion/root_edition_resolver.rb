# Resolves the root edition for link expansion.
# This will either be a caller-supplied edition or the best edition for the content_id
class LinkExpansion::RootEditionResolver
  def initialize(edition: nil, content_id: nil, locale: nil, with_drafts: false)
    @explicit_edition = edition
    @content_id = content_id
    @locale = locale
    @with_drafts = with_drafts
  end

  def edition
    return @edition if defined?(@edition)

    @edition = @explicit_edition || load
  end

  def id
    edition&.id
  end

private

  attr_reader :content_id, :locale, :with_drafts

  def load
    edition_ids = Queries::GetEditionIdsWithFallbacks.call(
      [content_id],
      locale_fallback_order: [locale, Edition::DEFAULT_LOCALE].uniq,
      state_fallback_order: with_drafts ? %i[draft published withdrawn] : %i[published withdrawn],
    )
    return nil if edition_ids.blank?

    # NOTE: we join unpublishing here so that we can work out if the edition is withdrawn, see EditionHash#withdrawn?
    Edition.with_document.with_unpublishing
      .select("editions.*", 'unpublishings.type AS "unpublishings.type"')
      .find_by(id: edition_ids.first)
  end
end
