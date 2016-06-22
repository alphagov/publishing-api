class RemoveRedundantTaxCreditsRedirects < ActiveRecord::Migration
  def up
    redirect_content_ids = [
      "64d2120f-2396-4033-8e91-45f3e1f49ad8",
      "6aecd670-0451-49d2-bce7-a4258be1adb3",
      "fefde62e-a660-41eb-a222-4f711a3208da"
    ]
    redirect_content_ids.each do |content_id|
      content_items = ContentItem.where(content_id: content_id)

      supporting_classes = [
        AccessLimit,
        Linkable,
        Location,
        State,
        Translation,
        Unpublishing,
        UserFacingVersion
      ]

      supporting_classes.each do |klass|
        klass.where(content_item: content_items).destroy_all
      end

      LockVersion.where(target: content_items).destroy_all

      content_items.destroy_all

      LinkSet.where(content_id: content_id).destroy_all
    end
  end
end
