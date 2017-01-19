module DependencyResolutionHelper
  def create_link_set
    link_set = FactoryGirl.create(:link_set, content_id: SecureRandom.uuid)
    link_set.content_id
  end

  def create_edition(
    content_id,
    base_path,
    factory: :live_edition,
    locale: "en",
    version: 1
  )
    FactoryGirl.create(factory,
      document: Document.find_or_create_by(content_id: content_id, locale: locale),
      base_path: base_path,
      user_facing_version: version,
    )
  end

  def create_link(from, to, link_type, link_position = 0)
    link_set = LinkSet.find_or_create_by(content_id: from)

    FactoryGirl.create(:link,
      link_set: link_set,
      target_content_id: to,
      link_type: link_type,
      position: link_position
    )
  end
end
