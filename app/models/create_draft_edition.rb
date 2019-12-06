class CreateDraftEdition
  def initialize(put_content, payload, previously_published_item)
    @put_content = put_content
    @payload = payload
    @previously_published_item = previously_published_item
  end

  def call
    edition.tap do
      fill_out_new_edition
    end
  end

private

  attr_reader :payload, :put_content, :previously_published_item

  def edition
    @edition ||= create_edition
  end

  def create_edition
    attributes = edition_attributes_from_payload.merge(
      state: "draft",
      content_store: "draft",
      user_facing_version: user_facing_version_number_for_new_draft,
    )
    document.editions.create!(attributes)
  end

  def user_facing_version_number_for_new_draft
    previously_published_item.user_facing_version
  end

  def document
    put_content.document
  end

  def fill_out_new_edition
    document.increment!(:stale_lock_version)
    set_document_owner
  end

  def set_document_owner
    owner_id = put_content.options[:owning_document_id]
    edition.document.update(owning_document_id: owner_id) if owner_id
  end

  def edition_attributes_from_payload
    payload.slice(*Edition::TOP_LEVEL_FIELDS)
  end
end
