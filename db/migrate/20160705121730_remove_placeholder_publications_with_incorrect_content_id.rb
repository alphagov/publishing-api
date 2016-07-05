class RemovePlaceholderPublicationsWithIncorrectContentId < ActiveRecord::Migration
  def up
    content_items = ContentItem.where(content_id: [
      "d44e0185-1dd6-42e9-ba79-7eb4d589284b", #/government/publications/defence-information-strategy/defence-information-strategy
      "53fed749-53ca-476f-9243-da67ea0e8ad7", #/government/publications/equality-information-report-2015
    ])
    supporting_classes = [
      AccessLimit,
      Linkable,
      Location,
      State,
      Translation,
      Unpublishing,
      UserFacingVersion,
    ]

    supporting_classes.each do |klass|
      klass.where(content_item: content_items).destroy_all
    end

    LockVersion.where(target: content_items).destroy_all

    content_items.destroy_all

    LinkSet.where(content_id: "some-content-id").destroy_all
  end
end
