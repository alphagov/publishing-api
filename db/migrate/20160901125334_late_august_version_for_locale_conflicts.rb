class LateAugustVersionForLocaleConflicts < ActiveRecord::Migration
  def up
    updated_time_range = -> (hash) do
      parsed = Time.zone.parse(hash[:updated_at])
      hash.merge(updated_at: (parsed..(parsed + 1.second)))
    end

    to_delete.map(&updated_time_range).each do |criteria|
      # we can use a datetime range in a where but not a find_by hence odd choice
      content_item = ContentItem.where(criteria).first
      delete(content_item) if content_item
    end
  end

  def delete(content_item)
    Services::DeleteContentItem.destroy_supporting_objects(content_item)
    content_item.destroy
  end

  def to_delete
    # This data was pulled using DataHygiene::DuplicateContentItem::VersionForLocale
    # from a 2016-08-31 database
    # The items to be deleted are chosen by first their state (supserseded items
    # are removed preferably, then draft) and the timestamp where items added
    # later are removed
    [
      # Content item: 05536c1b-f4bf-4daa-abb5-12064320202e, locale: es-419, version: 3
      # keeping id: 1009289, state: published, updated_at: 2016-08-30 09:25:06 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1009290, state: draft, updated_at: 2016-08-30 09:25:06 UTC, publishing_app: whitehall, document_type: contact
      { id: 1009290, content_id: "05536c1b-f4bf-4daa-abb5-12064320202e", updated_at: "2016-08-30 09:25:06 UTC" },

      # Content item: 06149563-ffe2-4cdc-9fc3-50a55f9a025e, locale: en, version: 2
      # keeping id: 1009332, state: superseded, updated_at: 2016-08-30 09:53:43 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1009333, state: superseded, updated_at: 2016-08-30 09:53:43 UTC, publishing_app: whitehall, document_type: contact
      { id: 1009333, content_id: "06149563-ffe2-4cdc-9fc3-50a55f9a025e", updated_at: "2016-08-30 09:53:43 UTC" },

      # Content item: 06149563-ffe2-4cdc-9fc3-50a55f9a025e, locale: en, version: 3
      # keeping id: 1009339, state: published, updated_at: 2016-08-30 09:55:49 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1009338, state: superseded, updated_at: 2016-08-30 09:55:49 UTC, publishing_app: whitehall, document_type: contact
      { id: 1009338, content_id: "06149563-ffe2-4cdc-9fc3-50a55f9a025e", updated_at: "2016-08-30 09:55:49 UTC" },

      # Content item: 10e88eb1-5122-484e-b46c-23d37ec898a5, locale: he, version: 3
      # keeping id: 1002427, state: superseded, updated_at: 2016-08-30 05:25:59 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1002428, state: superseded, updated_at: 2016-08-26 06:08:17 UTC, publishing_app: whitehall, document_type: contact
      { id: 1002428, content_id: "10e88eb1-5122-484e-b46c-23d37ec898a5", updated_at: "2016-08-26 06:08:17 UTC" },

      # Content item: 10e88eb1-5122-484e-b46c-23d37ec898a5, locale: he, version: 4
      # keeping id: 1009129, state: published, updated_at: 2016-08-30 05:26:16 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1009130, state: draft, updated_at: 2016-08-30 05:26:16 UTC, publishing_app: whitehall, document_type: contact
      { id: 1009130, content_id: "10e88eb1-5122-484e-b46c-23d37ec898a5", updated_at: "2016-08-30 05:26:16 UTC" },

      # Content item: 11d879c0-37ed-4c20-9377-e939b1f168c3, locale: en, version: 1
      # keeping id: 1000290, state: published, updated_at: 2016-08-25 08:30:50 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 438103, state: superseded, updated_at: 2016-03-07 12:56:51 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 438103, content_id: "11d879c0-37ed-4c20-9377-e939b1f168c3", updated_at: "2016-03-07 12:56:51 UTC" },

      # Content item: 3d4983f8-bb63-4b8b-8b3d-374e1825a326, locale: en, version: 2
      # keeping id: 1004374, state: published, updated_at: 2016-08-26 13:36:59 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1004373, state: superseded, updated_at: 2016-08-26 13:36:59 UTC, publishing_app: whitehall, document_type: contact
      { id: 1004373, content_id: "3d4983f8-bb63-4b8b-8b3d-374e1825a326", updated_at: "2016-08-26 13:36:59 UTC" },

      # Content item: 7a8ade3a-34af-40f1-b3d7-4434f8451523, locale: en, version: 10
      # keeping id: 1009678, state: published, updated_at: 2016-08-30 13:00:35 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1009675, state: superseded, updated_at: 2016-08-30 13:00:35 UTC, publishing_app: whitehall, document_type: contact
      { id: 1009675, content_id: "7a8ade3a-34af-40f1-b3d7-4434f8451523", updated_at: "2016-08-30 13:00:35 UTC" },

      # Content item: b9dfe152-5151-41c0-8694-60946b6b1469, locale: ja, version: 2
      # keeping id: 1002406, state: published, updated_at: 2016-08-26 02:12:43 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1002405, state: draft, updated_at: 2016-08-26 02:12:43 UTC, publishing_app: whitehall, document_type: contact
      { id: 1002405, content_id: "b9dfe152-5151-41c0-8694-60946b6b1469", updated_at: "2016-08-26 02:12:43 UTC" },

      # Content item: fff196ab-2fb0-4662-b7ec-f860dc3f2480, locale: ja, version: 4
      # keeping id: 1002401, state: published, updated_at: 2016-08-26 02:12:14 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 1002402, state: draft, updated_at: 2016-08-26 02:12:14 UTC, publishing_app: whitehall, document_type: contact
      { id: 1002402, content_id: "fff196ab-2fb0-4662-b7ec-f860dc3f2480", updated_at: "2016-08-26 02:12:14 UTC" },

    ]
  end
end
