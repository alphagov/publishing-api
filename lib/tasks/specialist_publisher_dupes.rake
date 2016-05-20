namespace :specialist_publisher_dupes do
  desc "Removes drafts for specialist publisher documents if they're duplicates"
  task remove_drafts: :environment do
    content_ids = ContentItem
      .where(publishing_app: "specialist-publisher")
      .where("created_at::date > '2016-02-20'::date")
      .where("created_at::date < '2016-03-28'::date")
      .pluck("DISTINCT content_id")

    content_ids.each do |content_id|
      scope = ContentItem.where(content_id: content_id)

      published = State.filter(scope, name: "published").first
      draft = State.filter(scope, name: "draft").first

      next unless published && draft

      published_fields = published.attributes.slice(ContentItem::TOP_LEVEL_FIELDS)
      draft_fields = draft.attributes.slice(ContentItem::TOP_LEVEL_FIELDS)

      if draft_fields == published_fields
        puts "Deleting duplicate draft ##{draft.id} (#{content_id})"
        LockVersion.find_by(target: draft).try(:destroy)
        UserFacingVersion.find_by(content_item: draft).try(:destroy)
        State.find_by(content_item: draft).try(:destroy)
        AccessLimit.find_by(content_item: draft).try(:destroy)
        Translation.find_by(content_item: draft).try(:destroy)
        Unpublishing.find_by(content_item: draft).try(:destroy)
        draft.destroy
      end
    end
  end
end
