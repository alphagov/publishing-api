class DeleteHtmlPublications < ActiveRecord::Migration
  def up
    # Safety check to ensure this doesn't get run more than once.
    # At time of writing, the max content_item_id in production
    # is 796460. Refuse to run this migration if there are no
    # HTML publications lower than this ID, as this means that
    # this migration has already been run.

    return if ContentItem.where("id < 796460").where(document_type: "html_publication").empty?

    ContentItem.transaction do
      results = ContentItem.where(document_type: "html_publication").pluck(:id, :content_id)
      ids = results.map { |r| r[0] }.uniq
      content_ids = results.map { |r| r[1] }.uniq

      State.where(content_item_id: ids).delete_all
      Location.where(content_item_id: ids).delete_all
      Translation.where(content_item_id: ids).delete_all
      UserFacingVersion.where(content_item_id: ids).delete_all
      ContentItem.where(id: ids).delete_all

      Link.joins(:link_set).where(link_sets: {content_id: content_ids}).delete_all
      LinkSet.where(content_id: content_ids).delete_all
    end
  end
end
