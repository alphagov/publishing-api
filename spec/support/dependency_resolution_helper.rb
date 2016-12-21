module DependencyResolutionHelper
  def create_link_set
    link_set = FactoryGirl.create(:link_set, content_id: SecureRandom.uuid)
    link_set.content_id
  end

  def create_content_item(
    content_id,
    base_path,
    state = "published",
    locale = "en",
    version = 1
  )
    FactoryGirl.create(
      :content_item,
      content_id: content_id,
      base_path: base_path,
      state: state,
      content_store: content_store_for(state),
      locale: locale,
      document_type: 'topical_event',
      details: {},
      user_facing_version: version,
    )
  end

  def content_store_for(state)
    return if state == 'superseded'
    state == 'draft' ? 'draft' : 'live'
  end

  def create_link(from, to, link_type, link_position = 0)
    link_set = LinkSet.find_or_create_by(content_id: from)

    FactoryGirl.create(
      :link,
      link_set: link_set,
      target_content_id: to,
      link_type: link_type,
      position: link_position
    )
  end
end
