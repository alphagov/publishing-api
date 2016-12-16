class ResolveVersionForLocaleConflicts < ActiveRecord::Migration
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
    # from a 2016-08-25 database
    # The items to be deleted are chosen by first their state (supserseded items
    # are removed preferably, then draft) and the timestamp where items added
    # later are removed
    [
      # Content item: 0227770e-0be5-46db-87c4-e1eac21e2a63, locale: en, version: 1
      # keeping id: 997028, state: published, updated_at: 2016-08-23 08:30:25 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 503687, state: superseded, updated_at: 2016-04-01 08:58:21 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 503687, content_id: "0227770e-0be5-46db-87c4-e1eac21e2a63", updated_at: "2016-04-01 08:58:21 UTC" },

      # Content item: 026bb1c0-c153-4e32-864c-da4e623e9546, locale: en, version: 3
      # keeping id: 855005, state: published, updated_at: 2016-07-19 14:00:51 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 855004, state: superseded, updated_at: 2016-07-19 13:19:38 UTC, publishing_app: whitehall, document_type: contact
      { id: 855004, content_id: "026bb1c0-c153-4e32-864c-da4e623e9546", updated_at: "2016-07-19 13:19:38 UTC" },

      # Content item: 03ba754c-756d-42cb-b1a6-2ae9ab5954f7, locale: en, version: 2
      # keeping id: 879711, state: published, updated_at: 2016-07-29 10:52:49 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 879712, state: draft, updated_at: 2016-07-29 10:52:49 UTC, publishing_app: whitehall, document_type: contact
      { id: 879712, content_id: "03ba754c-756d-42cb-b1a6-2ae9ab5954f7", updated_at: "2016-07-29 10:52:49 UTC" },

      # Content item: 05536c1b-f4bf-4daa-abb5-12064320202e, locale: es-419, version: 2
      # keeping id: 948943, state: published, updated_at: 2016-08-03 08:17:23 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 948944, state: draft, updated_at: 2016-08-03 08:17:23 UTC, publishing_app: whitehall, document_type: contact
      { id: 948944, content_id: "05536c1b-f4bf-4daa-abb5-12064320202e", updated_at: "2016-08-03 08:17:23 UTC" },

      # Content item: 09024331-c4ae-4ea1-af10-513d622a09a4, locale: en, version: 1
      # keeping id: 997026, state: published, updated_at: 2016-08-23 08:30:25 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 503679, state: superseded, updated_at: 2016-04-01 08:55:30 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 503679, content_id: "09024331-c4ae-4ea1-af10-513d622a09a4", updated_at: "2016-04-01 08:55:30 UTC" },

      # Content item: 0b045fc8-0400-4efb-a5ac-203debaa75d8, locale: hi, version: 2
      # keeping id: 997117, state: superseded, updated_at: 2016-08-23 09:17:41 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997118, state: superseded, updated_at: 2016-08-23 09:17:41 UTC, publishing_app: whitehall, document_type: contact
      { id: 997118, content_id: "0b045fc8-0400-4efb-a5ac-203debaa75d8", updated_at: "2016-08-23 09:17:41 UTC" },

      # Content item: 0b045fc8-0400-4efb-a5ac-203debaa75d8, locale: hi, version: 3
      # keeping id: 997892, state: published, updated_at: 2016-08-24 06:04:52 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997894, state: draft, updated_at: 2016-08-24 06:04:52 UTC, publishing_app: whitehall, document_type: contact
      { id: 997894, content_id: "0b045fc8-0400-4efb-a5ac-203debaa75d8", updated_at: "2016-08-24 06:04:52 UTC" },

      # Content item: 1726eb28-6bb9-4d84-b5b7-c760c3ad9460, locale: en, version: 1
      # keeping id: 864500, state: published, updated_at: 2016-07-21 13:00:08 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 440883, state: superseded, updated_at: 2016-03-07 13:01:48 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440883, content_id: "1726eb28-6bb9-4d84-b5b7-c760c3ad9460", updated_at: "2016-03-07 13:01:48 UTC" },

      # Content item: 1a48ad91-e0f7-47e0-a3b1-ead797bda8b8, locale: en, version: 1
      # keeping id: 970572, state: draft, updated_at: 2016-08-08 14:03:29 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 825272, state: superseded, updated_at: 2016-06-24 13:29:25 UTC, publishing_app: whitehall, document_type: official
      { id: 825272, content_id: "1a48ad91-e0f7-47e0-a3b1-ead797bda8b8", updated_at: "2016-06-24 13:29:25 UTC" },

      # Content item: 1c78f5a3-1785-4907-95da-d24a516801bf, locale: en, version: 1
      # keeping id: 844180, state: published, updated_at: 2016-07-12 08:45:05 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 442481, state: superseded, updated_at: 2016-03-09 12:26:19 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 442481, content_id: "1c78f5a3-1785-4907-95da-d24a516801bf", updated_at: "2016-03-09 12:26:19 UTC" },

      # Content item: 24760db7-10a8-4845-9c6a-b5a32ef91e4d, locale: en, version: 1
      # keeping id: 849109, state: published, updated_at: 2016-07-13 12:36:02 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 441376, state: superseded, updated_at: 2016-03-08 12:39:47 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 441376, content_id: "24760db7-10a8-4845-9c6a-b5a32ef91e4d", updated_at: "2016-03-08 12:39:47 UTC" },

      # Content item: 2600058f-a903-4a31-a7c8-dde75eb45d5a, locale: en, version: 2
      # keeping id: 974927, state: published, updated_at: 2016-08-09 14:15:29 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 974926, state: superseded, updated_at: 2016-08-09 14:15:29 UTC, publishing_app: whitehall, document_type: contact
      { id: 974926, content_id: "2600058f-a903-4a31-a7c8-dde75eb45d5a", updated_at: "2016-08-09 14:15:29 UTC" },

      # Content item: 267817c7-0873-4aac-8919-7d07de8c2ccb, locale: en, version: 1
      # keeping id: 853309, state: published, updated_at: 2016-07-19 08:19:59 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 853308, state: superseded, updated_at: 2016-07-18 11:11:31 UTC, publishing_app: whitehall, document_type: contact
      { id: 853308, content_id: "267817c7-0873-4aac-8919-7d07de8c2ccb", updated_at: "2016-07-18 11:11:31 UTC" },

      # Content item: 28a1d16a-2d27-46b5-bc39-3e7e09776991, locale: en, version: 1
      # keeping id: 977519, state: published, updated_at: 2016-08-11 08:30:23 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 439495, state: superseded, updated_at: 2016-03-07 12:59:19 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 439495, content_id: "28a1d16a-2d27-46b5-bc39-3e7e09776991", updated_at: "2016-03-07 12:59:19 UTC" },

      # Content item: 2a9c074c-15d8-4157-8154-719e6acd8c01, locale: en, version: 1
      # keeping id: 996319, state: superseded, updated_at: 2016-08-22 10:18:55 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 996320, state: superseded, updated_at: 2016-08-22 10:18:55 UTC, publishing_app: whitehall, document_type: contact
      { id: 996320, content_id: "2a9c074c-15d8-4157-8154-719e6acd8c01", updated_at: "2016-08-22 10:18:55 UTC" },

      # Content item: 2a9c074c-15d8-4157-8154-719e6acd8c01, locale: en, version: 2
      # keeping id: 996336, state: published, updated_at: 2016-08-22 10:27:40 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 996335, state: superseded, updated_at: 2016-08-22 10:27:40 UTC, publishing_app: whitehall, document_type: contact
      { id: 996335, content_id: "2a9c074c-15d8-4157-8154-719e6acd8c01", updated_at: "2016-08-22 10:27:40 UTC" },

      # Content item: 30644c5a-402b-4858-973f-caa74b9922db, locale: en, version: 2
      # keeping id: 974983, state: published, updated_at: 2016-08-09 14:37:31 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 974982, state: superseded, updated_at: 2016-08-09 14:37:31 UTC, publishing_app: whitehall, document_type: contact
      { id: 974982, content_id: "30644c5a-402b-4858-973f-caa74b9922db", updated_at: "2016-08-09 14:37:31 UTC" },

      # Content item: 30b5049e-2639-49e7-b219-bc85e31b1cb2, locale: en, version: 1
      # keeping id: 859666, state: published, updated_at: 2016-07-21 08:31:08 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 664435, state: superseded, updated_at: 2016-05-04 08:46:27 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 664435, content_id: "30b5049e-2639-49e7-b219-bc85e31b1cb2", updated_at: "2016-05-04 08:46:27 UTC" },

      # Content item: 32f0c60a-f044-4888-bdbb-f0487e36fbb8, locale: en, version: 1
      # keeping id: 864498, state: published, updated_at: 2016-07-21 13:00:07 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 440884, state: superseded, updated_at: 2016-03-07 13:01:48 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440884, content_id: "32f0c60a-f044-4888-bdbb-f0487e36fbb8", updated_at: "2016-03-07 13:01:48 UTC" },

      # Content item: 3523b765-9666-42e3-8e88-30f95cd9cffa, locale: en, version: 2
      # keeping id: 866789, state: superseded, updated_at: 2016-07-25 10:11:43 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 866790, state: superseded, updated_at: 2016-07-25 10:11:43 UTC, publishing_app: whitehall, document_type: contact
      { id: 866790, content_id: "3523b765-9666-42e3-8e88-30f95cd9cffa", updated_at: "2016-07-25 10:11:43 UTC" },

      # Content item: 3523b765-9666-42e3-8e88-30f95cd9cffa, locale: en, version: 4
      # keeping id: 993685, state: superseded, updated_at: 2016-08-19 08:37:20 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 993686, state: superseded, updated_at: 2016-08-19 08:37:20 UTC, publishing_app: whitehall, document_type: contact
      { id: 993686, content_id: "3523b765-9666-42e3-8e88-30f95cd9cffa", updated_at: "2016-08-19 08:37:20 UTC" },

      # Content item: 3523b765-9666-42e3-8e88-30f95cd9cffa, locale: en, version: 5
      # keeping id: 994276, state: published, updated_at: 2016-08-19 13:20:28 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 994275, state: superseded, updated_at: 2016-08-19 13:20:28 UTC, publishing_app: whitehall, document_type: contact
      { id: 994275, content_id: "3523b765-9666-42e3-8e88-30f95cd9cffa", updated_at: "2016-08-19 13:20:28 UTC" },

      # Content item: 361b59f7-c1c3-41fd-96f3-44716fe9a829, locale: en, version: 4
      # keeping id: 960735, state: published, updated_at: 2016-08-04 12:17:19 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 960734, state: superseded, updated_at: 2016-08-04 12:17:19 UTC, publishing_app: whitehall, document_type: contact
      { id: 960734, content_id: "361b59f7-c1c3-41fd-96f3-44716fe9a829", updated_at: "2016-08-04 12:17:19 UTC" },

      # Content item: 361bbc4b-297d-4802-8f03-0d11ed4d8c6f, locale: es-419, version: 3
      # keeping id: 947919, state: published, updated_at: 2016-08-03 07:22:55 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 947920, state: draft, updated_at: 2016-08-03 07:22:55 UTC, publishing_app: whitehall, document_type: contact
      { id: 947920, content_id: "361bbc4b-297d-4802-8f03-0d11ed4d8c6f", updated_at: "2016-08-03 07:22:55 UTC" },

      # Content item: 37e0386b-0472-4202-ab05-e8599f1953a6, locale: en, version: 2
      # keeping id: 877552, state: published, updated_at: 2016-07-28 16:59:16 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 877551, state: superseded, updated_at: 2016-07-28 16:59:16 UTC, publishing_app: whitehall, document_type: contact
      { id: 877551, content_id: "37e0386b-0472-4202-ab05-e8599f1953a6", updated_at: "2016-07-28 16:59:16 UTC" },

      # Content item: 3c14b55f-b630-4089-85e9-62503358857c, locale: en, version: 4
      # keeping id: 999019, state: published, updated_at: 2016-08-24 14:48:24 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 999020, state: superseded, updated_at: 2016-08-24 14:48:24 UTC, publishing_app: whitehall, document_type: contact
      { id: 999020, content_id: "3c14b55f-b630-4089-85e9-62503358857c", updated_at: "2016-08-24 14:48:24 UTC" },

      # Content item: 3c152d76-e62b-4966-84e1-fe1e98b56bdf, locale: en, version: 1
      # keeping id: 981798, state: published, updated_at: 2016-08-15 11:12:01 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 981797, state: superseded, updated_at: 2016-08-15 11:12:01 UTC, publishing_app: whitehall, document_type: contact
      { id: 981797, content_id: "3c152d76-e62b-4966-84e1-fe1e98b56bdf", updated_at: "2016-08-15 11:12:01 UTC" },

      # Content item: 424277ac-763a-4d6b-a286-4de2b145a015, locale: en, version: 1
      # keeping id: 859668, state: published, updated_at: 2016-07-21 08:31:09 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 664415, state: superseded, updated_at: 2016-05-04 08:35:39 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 664415, content_id: "424277ac-763a-4d6b-a286-4de2b145a015", updated_at: "2016-05-04 08:35:39 UTC" },

      # Content item: 44a9f89b-8425-44d8-8657-6d867fec669d, locale: en, version: 1
      # keeping id: 981920, state: published, updated_at: 2016-08-15 12:56:21 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 438762, state: superseded, updated_at: 2016-03-07 12:58:01 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 438762, content_id: "44a9f89b-8425-44d8-8657-6d867fec669d", updated_at: "2016-03-07 12:58:01 UTC" },

      # Content item: 45d7d1b2-54b0-4d01-84a3-dd8dd16c85e5, locale: en, version: 3
      # keeping id: 998397, state: superseded, updated_at: 2016-08-24 11:12:07 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 998398, state: superseded, updated_at: 2016-08-24 11:12:07 UTC, publishing_app: whitehall, document_type: contact
      { id: 998398, content_id: "45d7d1b2-54b0-4d01-84a3-dd8dd16c85e5", updated_at: "2016-08-24 11:12:07 UTC" },

      # Content item: 45d7d1b2-54b0-4d01-84a3-dd8dd16c85e5, locale: en, version: 4
      # keeping id: 998418, state: superseded, updated_at: 2016-08-24 11:16:57 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 998419, state: superseded, updated_at: 2016-08-24 11:16:57 UTC, publishing_app: whitehall, document_type: contact
      { id: 998419, content_id: "45d7d1b2-54b0-4d01-84a3-dd8dd16c85e5", updated_at: "2016-08-24 11:16:57 UTC" },

      # Content item: 45d7d1b2-54b0-4d01-84a3-dd8dd16c85e5, locale: en, version: 7
      # keeping id: 998473, state: published, updated_at: 2016-08-24 11:32:39 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 998472, state: superseded, updated_at: 2016-08-24 11:32:39 UTC, publishing_app: whitehall, document_type: contact
      { id: 998472, content_id: "45d7d1b2-54b0-4d01-84a3-dd8dd16c85e5", updated_at: "2016-08-24 11:32:39 UTC" },

      # Content item: 471a9d2b-e75c-4367-b8b8-0d796922b470, locale: en, version: 2
      # keeping id: 947552, state: published, updated_at: 2016-08-02 14:09:44 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 947553, state: superseded, updated_at: 2016-08-02 14:09:44 UTC, publishing_app: whitehall, document_type: contact
      { id: 947553, content_id: "471a9d2b-e75c-4367-b8b8-0d796922b470", updated_at: "2016-08-02 14:09:44 UTC" },

      # Content item: 48b11160-3a57-4ff8-a930-140d9ab64ba1, locale: en, version: 2
      # keeping id: 974941, state: published, updated_at: 2016-08-09 14:19:48 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 974940, state: superseded, updated_at: 2016-08-09 14:19:48 UTC, publishing_app: whitehall, document_type: contact
      { id: 974940, content_id: "48b11160-3a57-4ff8-a930-140d9ab64ba1", updated_at: "2016-08-09 14:19:48 UTC" },

      # Content item: 495badc9-5f62-4e49-89a6-2ed3951d46ae, locale: en, version: 1
      # keeping id: 981789, state: published, updated_at: 2016-08-15 11:09:43 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 981788, state: superseded, updated_at: 2016-08-15 11:09:43 UTC, publishing_app: whitehall, document_type: contact
      { id: 981788, content_id: "495badc9-5f62-4e49-89a6-2ed3951d46ae", updated_at: "2016-08-15 11:09:43 UTC" },

      # Content item: 49b2b3a7-ae88-4514-ad36-cebee3189fcd, locale: en, version: 1
      # keeping id: 859662, state: published, updated_at: 2016-07-21 08:31:06 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 664455, state: superseded, updated_at: 2016-05-04 08:52:44 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 664455, content_id: "49b2b3a7-ae88-4514-ad36-cebee3189fcd", updated_at: "2016-05-04 08:52:44 UTC" },

      # Content item: 4ba1bed6-4737-41ce-be11-4c58272d8682, locale: en, version: 1
      # keeping id: 854011, state: published, updated_at: 2016-07-18 16:25:52 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 854012, state: draft, updated_at: 2016-07-18 16:25:52 UTC, publishing_app: whitehall, document_type: contact
      { id: 854012, content_id: "4ba1bed6-4737-41ce-be11-4c58272d8682", updated_at: "2016-07-18 16:25:52 UTC" },

      # Content item: 4d25546d-ea6a-45af-986f-f173c4e97359, locale: en, version: 2
      # keeping id: 995746, state: published, updated_at: 2016-08-22 07:44:17 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 995744, state: superseded, updated_at: 2016-08-22 07:44:17 UTC, publishing_app: whitehall, document_type: contact
      { id: 995744, content_id: "4d25546d-ea6a-45af-986f-f173c4e97359", updated_at: "2016-08-22 07:44:17 UTC" },

      # Content item: 4dd4ddf8-3593-4043-9841-7c057da61b61, locale: en, version: 1
      # keeping id: 849453, state: published, updated_at: 2016-07-13 12:55:57 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 838368, state: superseded, updated_at: 2016-07-05 13:22:33 UTC, publishing_app: whitehall, document_type: official
      { id: 838368, content_id: "4dd4ddf8-3593-4043-9841-7c057da61b61", updated_at: "2016-07-05 13:22:33 UTC" },

      # Content item: 503d1c6c-042a-49ce-aa60-55f3a1ad253c, locale: en, version: 1
      # keeping id: 947716, state: published, updated_at: 2016-08-02 15:46:53 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 671171, state: superseded, updated_at: 2016-05-10 15:49:37 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 671171, content_id: "503d1c6c-042a-49ce-aa60-55f3a1ad253c", updated_at: "2016-05-10 15:49:37 UTC" },

      # Content item: 52252c4d-fc5d-4033-8a6a-c55ee0dbaf7b, locale: hi, version: 2
      # keeping id: 997124, state: superseded, updated_at: 2016-08-23 09:18:41 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997125, state: superseded, updated_at: 2016-08-23 09:18:41 UTC, publishing_app: whitehall, document_type: contact
      { id: 997125, content_id: "52252c4d-fc5d-4033-8a6a-c55ee0dbaf7b", updated_at: "2016-08-23 09:18:41 UTC" },

      # Content item: 52252c4d-fc5d-4033-8a6a-c55ee0dbaf7b, locale: hi, version: 3
      # keeping id: 997905, state: published, updated_at: 2016-08-24 06:06:55 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997907, state: draft, updated_at: 2016-08-24 06:06:55 UTC, publishing_app: whitehall, document_type: contact
      { id: 997907, content_id: "52252c4d-fc5d-4033-8a6a-c55ee0dbaf7b", updated_at: "2016-08-24 06:06:55 UTC" },

      # Content item: 571618ad-0b56-423e-9f26-fe14325d9bb5, locale: en, version: 1
      # keeping id: 877961, state: published, updated_at: 2016-07-29 08:30:43 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 440866, state: superseded, updated_at: 2016-03-07 13:01:46 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440866, content_id: "571618ad-0b56-423e-9f26-fe14325d9bb5", updated_at: "2016-03-07 13:01:46 UTC" },

      # Content item: 5765ccad-44fb-430b-bda6-d47152429fd8, locale: en, version: 1
      # keeping id: 997024, state: published, updated_at: 2016-08-23 08:30:25 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 503691, state: superseded, updated_at: 2016-04-01 09:00:09 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 503691, content_id: "5765ccad-44fb-430b-bda6-d47152429fd8", updated_at: "2016-04-01 09:00:09 UTC" },

      # Content item: 581baf19-e943-497c-bee7-41661c8bf0a7, locale: en, version: 1
      # keeping id: 977503, state: draft, updated_at: 2016-08-11 08:30:18 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 437717, state: superseded, updated_at: 2016-03-07 12:56:09 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 437717, content_id: "581baf19-e943-497c-bee7-41661c8bf0a7", updated_at: "2016-03-07 12:56:09 UTC" },

      # Content item: 5d90b862-21d8-4056-94a0-98be454a3ee4, locale: en, version: 2
      # keeping id: 979373, state: published, updated_at: 2016-08-11 15:16:21 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 979372, state: superseded, updated_at: 2016-08-11 15:16:21 UTC, publishing_app: whitehall, document_type: contact
      { id: 979372, content_id: "5d90b862-21d8-4056-94a0-98be454a3ee4", updated_at: "2016-08-11 15:16:21 UTC" },

      # Content item: 5e5b5bb1-a71a-4088-8ae4-23fc23aa438a, locale: en, version: 1
      # keeping id: 854155, state: superseded, updated_at: 2016-07-19 07:53:11 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 854156, state: superseded, updated_at: 2016-07-19 07:54:16 UTC, publishing_app: whitehall, document_type: contact
      { id: 854156, content_id: "5e5b5bb1-a71a-4088-8ae4-23fc23aa438a", updated_at: "2016-07-19 07:54:16 UTC" },

      # Content item: 5e5b5bb1-a71a-4088-8ae4-23fc23aa438a, locale: en, version: 2
      # keeping id: 855589, state: published, updated_at: 2016-07-20 08:01:47 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 855590, state: draft, updated_at: 2016-07-20 08:01:47 UTC, publishing_app: whitehall, document_type: contact
      { id: 855590, content_id: "5e5b5bb1-a71a-4088-8ae4-23fc23aa438a", updated_at: "2016-07-20 08:01:47 UTC" },

      # Content item: 5e8fe08a-dd12-411e-8da5-e35b635b64b1, locale: en, version: 2
      # keeping id: 977446, state: published, updated_at: 2016-08-11 08:06:36 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 977445, state: superseded, updated_at: 2016-08-11 08:06:36 UTC, publishing_app: whitehall, document_type: contact
      { id: 977445, content_id: "5e8fe08a-dd12-411e-8da5-e35b635b64b1", updated_at: "2016-08-11 08:06:36 UTC" },

      # Content item: 5f1ff282-441c-4819-9e17-7b132dc58387, locale: en, version: 1
      # keeping id: 959977, state: published, updated_at: 2016-08-03 15:25:34 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 959978, state: draft, updated_at: 2016-08-03 15:25:34 UTC, publishing_app: whitehall, document_type: contact
      { id: 959978, content_id: "5f1ff282-441c-4819-9e17-7b132dc58387", updated_at: "2016-08-03 15:25:34 UTC" },

      # Content item: 624f2185-a57a-4745-aeb7-7c3b89ba834e, locale: en, version: 4
      # keeping id: 977015, state: published, updated_at: 2016-08-10 14:45:58 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 977016, state: draft, updated_at: 2016-08-10 14:45:58 UTC, publishing_app: whitehall, document_type: contact
      { id: 977016, content_id: "624f2185-a57a-4745-aeb7-7c3b89ba834e", updated_at: "2016-08-10 14:45:58 UTC" },

      # Content item: 63f789f1-3a4e-4f26-86a6-dddc6e42ff4d, locale: en, version: 1
      # keeping id: 815433, state: draft, updated_at: 2016-06-10 15:10:42 UTC, publishing_app: publisher, document_type: answer
      # deleting id: 815434, state: draft, updated_at: 2016-06-10 15:10:42 UTC, publishing_app: publisher, document_type: answer
      { id: 815434, content_id: "63f789f1-3a4e-4f26-86a6-dddc6e42ff4d", updated_at: "2016-06-10 15:10:42 UTC" },

      # Content item: 6554618a-9d9d-4dbc-92aa-b7238532a60a, locale: en, version: 1
      # keeping id: 947708, state: published, updated_at: 2016-08-02 15:43:00 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 815494, state: superseded, updated_at: 2016-06-10 16:07:30 UTC, publishing_app: whitehall, document_type: official
      { id: 815494, content_id: "6554618a-9d9d-4dbc-92aa-b7238532a60a", updated_at: "2016-06-10 16:07:30 UTC" },

      # Content item: 663c23e4-f529-4552-8dbd-1f8854b8564d, locale: hi, version: 2
      # keeping id: 997119, state: superseded, updated_at: 2016-08-23 09:18:01 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997120, state: superseded, updated_at: 2016-08-24 06:05:18 UTC, publishing_app: whitehall, document_type: contact
      { id: 997120, content_id: "663c23e4-f529-4552-8dbd-1f8854b8564d", updated_at: "2016-08-24 06:05:18 UTC" },

      # Content item: 663c23e4-f529-4552-8dbd-1f8854b8564d, locale: hi, version: 3
      # keeping id: 997896, state: published, updated_at: 2016-08-24 06:05:36 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997898, state: draft, updated_at: 2016-08-24 06:05:36 UTC, publishing_app: whitehall, document_type: contact
      { id: 997898, content_id: "663c23e4-f529-4552-8dbd-1f8854b8564d", updated_at: "2016-08-24 06:05:36 UTC" },

      # Content item: 666d2d62-3eb1-4900-b882-55e800479e76, locale: hi, version: 2
      # keeping id: 997133, state: superseded, updated_at: 2016-08-23 09:20:57 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997135, state: superseded, updated_at: 2016-08-23 09:20:57 UTC, publishing_app: whitehall, document_type: contact
      { id: 997135, content_id: "666d2d62-3eb1-4900-b882-55e800479e76", updated_at: "2016-08-23 09:20:57 UTC" },

      # Content item: 666d2d62-3eb1-4900-b882-55e800479e76, locale: hi, version: 3
      # keeping id: 997926, state: published, updated_at: 2016-08-24 06:12:54 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997927, state: draft, updated_at: 2016-08-24 06:12:54 UTC, publishing_app: whitehall, document_type: contact
      { id: 997927, content_id: "666d2d62-3eb1-4900-b882-55e800479e76", updated_at: "2016-08-24 06:12:54 UTC" },

      # Content item: 69e5157c-a9d5-4b6a-ae86-4cef26e253fc, locale: en, version: 1
      # keeping id: 979269, state: published, updated_at: 2016-08-11 14:38:50 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 979268, state: superseded, updated_at: 2016-08-11 14:38:50 UTC, publishing_app: whitehall, document_type: contact
      { id: 979268, content_id: "69e5157c-a9d5-4b6a-ae86-4cef26e253fc", updated_at: "2016-08-11 14:38:50 UTC" },

      # Content item: 69f199bf-8f3b-463e-a466-554d7949b253, locale: en, version: 1
      # keeping id: 981952, state: published, updated_at: 2016-08-15 13:14:53 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 981951, state: superseded, updated_at: 2016-08-15 13:14:53 UTC, publishing_app: whitehall, document_type: contact
      { id: 981951, content_id: "69f199bf-8f3b-463e-a466-554d7949b253", updated_at: "2016-08-15 13:14:53 UTC" },

      # Content item: 6b06384e-cd61-4262-9b6e-e8b69f0be40a, locale: es-419, version: 2
      # keeping id: 949222, state: published, updated_at: 2016-08-03 10:08:57 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 949223, state: draft, updated_at: 2016-08-03 10:08:57 UTC, publishing_app: whitehall, document_type: contact
      { id: 949223, content_id: "6b06384e-cd61-4262-9b6e-e8b69f0be40a", updated_at: "2016-08-03 10:08:57 UTC" },

      # Content item: 6eaa0210-7299-4ca6-a694-3ae6854639aa, locale: hi, version: 4
      # keeping id: 997921, state: published, updated_at: 2016-08-24 06:09:37 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997922, state: draft, updated_at: 2016-08-24 06:09:37 UTC, publishing_app: whitehall, document_type: contact
      { id: 997922, content_id: "6eaa0210-7299-4ca6-a694-3ae6854639aa", updated_at: "2016-08-24 06:09:37 UTC" },

      # Content item: 74804ab3-2169-4ddf-b291-d8c8a717552e, locale: en, version: 2
      # keeping id: 974931, state: published, updated_at: 2016-08-09 14:16:02 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 974930, state: superseded, updated_at: 2016-08-09 14:16:02 UTC, publishing_app: whitehall, document_type: contact
      { id: 974930, content_id: "74804ab3-2169-4ddf-b291-d8c8a717552e", updated_at: "2016-08-09 14:16:02 UTC" },

      # Content item: 7a8ade3a-34af-40f1-b3d7-4434f8451523, locale: en, version: 5
      # keeping id: 971751, state: superseded, updated_at: 2016-08-09 07:44:09 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 971752, state: superseded, updated_at: 2016-08-09 07:44:09 UTC, publishing_app: whitehall, document_type: contact
      { id: 971752, content_id: "7a8ade3a-34af-40f1-b3d7-4434f8451523", updated_at: "2016-08-09 07:44:09 UTC" },

      # Content item: 7a8ade3a-34af-40f1-b3d7-4434f8451523, locale: en, version: 6
      # keeping id: 980503, state: superseded, updated_at: 2016-08-12 14:20:09 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 980504, state: superseded, updated_at: 2016-08-12 14:20:09 UTC, publishing_app: whitehall, document_type: contact
      { id: 980504, content_id: "7a8ade3a-34af-40f1-b3d7-4434f8451523", updated_at: "2016-08-12 14:20:09 UTC" },

      # Content item: 7a8ade3a-34af-40f1-b3d7-4434f8451523, locale: en, version: 9
      # keeping id: 981460, state: published, updated_at: 2016-08-15 09:13:07 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 981459, state: superseded, updated_at: 2016-08-15 09:13:07 UTC, publishing_app: whitehall, document_type: contact
      { id: 981459, content_id: "7a8ade3a-34af-40f1-b3d7-4434f8451523", updated_at: "2016-08-15 09:13:07 UTC" },

      # Content item: 81214144-ca71-4632-8324-fbe911a3c217, locale: en, version: 2
      # keeping id: 854577, state: published, updated_at: 2016-07-19 10:33:48 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 854576, state: superseded, updated_at: 2016-07-19 10:33:48 UTC, publishing_app: whitehall, document_type: contact
      { id: 854576, content_id: "81214144-ca71-4632-8324-fbe911a3c217", updated_at: "2016-07-19 10:33:48 UTC" },

      # Content item: 8483a1bc-6ade-4cab-a737-00bcd3ab16ac, locale: en, version: 2
      # keeping id: 885577, state: superseded, updated_at: 2016-08-01 10:22:58 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 885578, state: superseded, updated_at: 2016-08-01 10:22:59 UTC, publishing_app: whitehall, document_type: contact
      { id: 885578, content_id: "8483a1bc-6ade-4cab-a737-00bcd3ab16ac", updated_at: "2016-08-01 10:22:59 UTC" },

      # Content item: 8483a1bc-6ade-4cab-a737-00bcd3ab16ac, locale: en, version: 3
      # keeping id: 885589, state: published, updated_at: 2016-08-01 10:25:56 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 885588, state: superseded, updated_at: 2016-08-01 10:25:56 UTC, publishing_app: whitehall, document_type: contact
      { id: 885588, content_id: "8483a1bc-6ade-4cab-a737-00bcd3ab16ac", updated_at: "2016-08-01 10:25:56 UTC" },

      # Content item: 86531212-186c-4bc7-8a57-bbd844479039, locale: hi, version: 4
      # keeping id: 997911, state: published, updated_at: 2016-08-24 06:07:56 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997913, state: draft, updated_at: 2016-08-24 06:07:56 UTC, publishing_app: whitehall, document_type: contact
      { id: 997913, content_id: "86531212-186c-4bc7-8a57-bbd844479039", updated_at: "2016-08-24 06:07:56 UTC" },

      # Content item: 8849b5c9-c723-4e83-9bd8-230297c5015e, locale: en, version: 1
      # keeping id: 859664, state: published, updated_at: 2016-07-21 08:31:07 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 664412, state: superseded, updated_at: 2016-05-04 08:34:04 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 664412, content_id: "8849b5c9-c723-4e83-9bd8-230297c5015e", updated_at: "2016-05-04 08:34:04 UTC" },

      # Content item: 8b975642-ab36-4b57-8f6b-780315525ff1, locale: hi, version: 4
      # keeping id: 997916, state: published, updated_at: 2016-08-24 06:08:47 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997918, state: draft, updated_at: 2016-08-24 06:08:47 UTC, publishing_app: whitehall, document_type: contact
      { id: 997918, content_id: "8b975642-ab36-4b57-8f6b-780315525ff1", updated_at: "2016-08-24 06:08:47 UTC" },

      # Content item: 8c74e147-ca59-44a9-b5b8-9c3704183c95, locale: en, version: 1
      # keeping id: 818620, state: published, updated_at: 2016-08-18 15:40:25 UTC, publishing_app: publisher, document_type: guide
      # deleting id: 818621, state: draft, updated_at: 2016-06-14 10:41:09 UTC, publishing_app: publisher, document_type: guide
      { id: 818621, content_id: "8c74e147-ca59-44a9-b5b8-9c3704183c95", updated_at: "2016-06-14 10:41:09 UTC" },

      # Content item: 8e2a7b3b-d946-440b-98a9-64fcd8a638dd, locale: en, version: 1
      # keeping id: 855624, state: published, updated_at: 2016-07-20 08:30:39 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 440075, state: superseded, updated_at: 2016-03-07 13:00:22 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440075, content_id: "8e2a7b3b-d946-440b-98a9-64fcd8a638dd", updated_at: "2016-03-07 13:00:22 UTC" },

      # Content item: 8e34eeb1-a736-4275-b3d3-7bf8c320fc60, locale: en, version: 1
      # keeping id: 994793, state: published, updated_at: 2016-08-22 07:43:28 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 994791, state: superseded, updated_at: 2016-08-19 16:04:21 UTC, publishing_app: whitehall, document_type: contact
      { id: 994791, content_id: "8e34eeb1-a736-4275-b3d3-7bf8c320fc60", updated_at: "2016-08-19 16:04:21 UTC" },

      # Content item: 90276a79-fa61-4fd6-94da-f1f6759f0c43, locale: en, version: 1
      # keeping id: 997030, state: published, updated_at: 2016-08-23 08:30:26 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 503660, state: superseded, updated_at: 2016-04-01 08:47:45 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 503660, content_id: "90276a79-fa61-4fd6-94da-f1f6759f0c43", updated_at: "2016-04-01 08:47:45 UTC" },

      # Content item: 90424844-c358-48ce-ae78-dd3a3eeafcd7, locale: en, version: 2
      # keeping id: 886575, state: superseded, updated_at: 2016-08-01 15:47:24 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 886576, state: superseded, updated_at: 2016-08-01 15:47:24 UTC, publishing_app: whitehall, document_type: contact
      { id: 886576, content_id: "90424844-c358-48ce-ae78-dd3a3eeafcd7", updated_at: "2016-08-01 15:47:24 UTC" },

      # Content item: 90424844-c358-48ce-ae78-dd3a3eeafcd7, locale: en, version: 3
      # keeping id: 916669, state: superseded, updated_at: 2016-08-02 12:46:03 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 916670, state: superseded, updated_at: 2016-08-02 12:46:03 UTC, publishing_app: whitehall, document_type: contact
      { id: 916670, content_id: "90424844-c358-48ce-ae78-dd3a3eeafcd7", updated_at: "2016-08-02 12:46:03 UTC" },

      # Content item: 90424844-c358-48ce-ae78-dd3a3eeafcd7, locale: en, version: 4
      # keeping id: 997643, state: published, updated_at: 2016-08-23 14:24:31 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997642, state: superseded, updated_at: 2016-08-23 14:24:31 UTC, publishing_app: whitehall, document_type: contact
      { id: 997642, content_id: "90424844-c358-48ce-ae78-dd3a3eeafcd7", updated_at: "2016-08-23 14:24:31 UTC" },

      # Content item: 925fe1aa-4a73-4fc9-b526-60dcd83be988, locale: es-419, version: 4
      # keeping id: 975485, state: published, updated_at: 2016-08-10 09:36:10 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 975487, state: draft, updated_at: 2016-08-10 09:36:10 UTC, publishing_app: whitehall, document_type: contact
      { id: 975487, content_id: "925fe1aa-4a73-4fc9-b526-60dcd83be988", updated_at: "2016-08-10 09:36:10 UTC" },

      # Content item: 973bcad9-1ebe-4f6a-936f-4c0e7e4c4692, locale: en, version: 1
      # keeping id: 849955, state: published, updated_at: 2016-07-14 08:30:25 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 436238, state: superseded, updated_at: 2016-03-07 12:53:27 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 436238, content_id: "973bcad9-1ebe-4f6a-936f-4c0e7e4c4692", updated_at: "2016-03-07 12:53:27 UTC" },

      # Content item: 97df9433-1da7-40ec-b4c5-54b4ac5ead2c, locale: en, version: 1
      # keeping id: 868598, state: published, updated_at: 2016-07-26 08:30:14 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 440862, state: superseded, updated_at: 2016-03-07 13:01:46 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440862, content_id: "97df9433-1da7-40ec-b4c5-54b4ac5ead2c", updated_at: "2016-03-07 13:01:46 UTC" },

      # Content item: 9d806ea1-2181-4dfd-afaf-ffffb57daf0f, locale: en, version: 1
      # keeping id: 871209, state: published, updated_at: 2016-07-28 08:30:59 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 439528, state: superseded, updated_at: 2016-03-07 12:59:23 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 439528, content_id: "9d806ea1-2181-4dfd-afaf-ffffb57daf0f", updated_at: "2016-03-07 12:59:23 UTC" },

      # Content item: aa82ebd3-3740-4bf2-b6fd-910537442578, locale: en, version: 2
      # keeping id: 866786, state: superseded, updated_at: 2016-07-25 10:10:54 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 866787, state: superseded, updated_at: 2016-07-25 10:10:54 UTC, publishing_app: whitehall, document_type: contact
      { id: 866787, content_id: "aa82ebd3-3740-4bf2-b6fd-910537442578", updated_at: "2016-07-25 10:10:54 UTC" },

      # Content item: aa82ebd3-3740-4bf2-b6fd-910537442578, locale: en, version: 3
      # keeping id: 884436, state: published, updated_at: 2016-07-29 15:11:05 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 884437, state: draft, updated_at: 2016-07-29 15:11:05 UTC, publishing_app: whitehall, document_type: contact
      { id: 884437, content_id: "aa82ebd3-3740-4bf2-b6fd-910537442578", updated_at: "2016-07-29 15:11:05 UTC" },

      # Content item: abde79ec-4a3e-4bc8-b5b4-c0293f9f2ff2, locale: en, version: 1
      # keeping id: 840982, state: published, updated_at: 2016-07-08 11:21:32 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 840983, state: draft, updated_at: 2016-07-08 11:21:32 UTC, publishing_app: whitehall, document_type: contact
      { id: 840983, content_id: "abde79ec-4a3e-4bc8-b5b4-c0293f9f2ff2", updated_at: "2016-07-08 11:21:32 UTC" },

      # Content item: ac17f3ae-1406-491f-a2a6-6b3c2cca025d, locale: en, version: 1
      # keeping id: 949044, state: published, updated_at: 2016-08-03 08:30:32 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 503518, state: superseded, updated_at: 2016-03-31 16:02:17 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 503518, content_id: "ac17f3ae-1406-491f-a2a6-6b3c2cca025d", updated_at: "2016-03-31 16:02:17 UTC" },

      # Content item: acb39ae2-45e6-4d6d-9617-4914bf79cc67, locale: en, version: 2
      # keeping id: 996396, state: published, updated_at: 2016-08-22 11:50:51 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 996395, state: superseded, updated_at: 2016-08-22 11:50:51 UTC, publishing_app: whitehall, document_type: contact
      { id: 996395, content_id: "acb39ae2-45e6-4d6d-9617-4914bf79cc67", updated_at: "2016-08-22 11:50:51 UTC" },

      # Content item: b04f3789-5ceb-4422-a3b3-761114b9ef0f, locale: en, version: 1
      # keeping id: 868596, state: published, updated_at: 2016-07-26 08:30:14 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 440861, state: superseded, updated_at: 2016-03-07 13:01:46 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440861, content_id: "b04f3789-5ceb-4422-a3b3-761114b9ef0f", updated_at: "2016-03-07 13:01:46 UTC" },

      # Content item: b07de3dc-80e4-4689-9c1b-6d17a24a1484, locale: en, version: 1
      # keeping id: 877959, state: published, updated_at: 2016-07-29 08:30:41 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 664456, state: superseded, updated_at: 2016-05-04 08:54:05 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 664456, content_id: "b07de3dc-80e4-4689-9c1b-6d17a24a1484", updated_at: "2016-05-04 08:54:05 UTC" },

      # Content item: b2e2411c-8423-40ec-98c6-123718f7b3e8, locale: en, version: 1
      # keeping id: 849054, state: published, updated_at: 2016-07-13 12:09:25 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 849055, state: draft, updated_at: 2016-07-13 12:09:25 UTC, publishing_app: whitehall, document_type: contact
      { id: 849055, content_id: "b2e2411c-8423-40ec-98c6-123718f7b3e8", updated_at: "2016-07-13 12:09:25 UTC" },

      # Content item: b57b7104-0186-4b14-8bce-e4f1853892d4, locale: en, version: 2
      # keeping id: 868651, state: superseded, updated_at: 2016-07-26 09:22:45 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 868652, state: superseded, updated_at: 2016-07-26 09:22:45 UTC, publishing_app: whitehall, document_type: contact
      { id: 868652, content_id: "b57b7104-0186-4b14-8bce-e4f1853892d4", updated_at: "2016-07-26 09:22:45 UTC" },

      # Content item: b5e99c14-ae74-4857-b725-eda82e6ccf12, locale: en, version: 1
      # keeping id: 859672, state: published, updated_at: 2016-07-21 08:31:15 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 572221, state: superseded, updated_at: 2016-04-12 11:21:13 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 572221, content_id: "b5e99c14-ae74-4857-b725-eda82e6ccf12", updated_at: "2016-04-12 11:21:13 UTC" },

      # Content item: b6fb15f6-9696-4eab-9fd5-23df8383f118, locale: hi, version: 4
      # keeping id: 997902, state: published, updated_at: 2016-08-24 06:06:16 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997903, state: draft, updated_at: 2016-08-24 06:06:16 UTC, publishing_app: whitehall, document_type: contact
      { id: 997903, content_id: "b6fb15f6-9696-4eab-9fd5-23df8383f118", updated_at: "2016-08-24 06:06:16 UTC" },

      # Content item: b73b6fad-57f5-4236-8f35-adc28083cd74, locale: en, version: 2
      # keeping id: 974921, state: published, updated_at: 2016-08-09 14:13:04 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 974920, state: superseded, updated_at: 2016-08-09 14:13:04 UTC, publishing_app: whitehall, document_type: contact
      { id: 974920, content_id: "b73b6fad-57f5-4236-8f35-adc28083cd74", updated_at: "2016-08-09 14:13:04 UTC" },

      # Content item: bad16524-add5-431d-999b-a64416db81d1, locale: en, version: 4
      # keeping id: 886771, state: superseded, updated_at: 2016-08-02 07:59:10 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 886772, state: superseded, updated_at: 2016-08-02 07:59:10 UTC, publishing_app: whitehall, document_type: contact
      { id: 886772, content_id: "bad16524-add5-431d-999b-a64416db81d1", updated_at: "2016-08-02 07:59:10 UTC" },

      # Content item: bad16524-add5-431d-999b-a64416db81d1, locale: en, version: 5
      # keeping id: 947604, state: published, updated_at: 2016-08-02 14:43:53 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 947603, state: superseded, updated_at: 2016-08-02 14:43:53 UTC, publishing_app: whitehall, document_type: contact
      { id: 947603, content_id: "bad16524-add5-431d-999b-a64416db81d1", updated_at: "2016-08-02 14:43:53 UTC" },

      # Content item: bd166f03-2752-4a20-bf43-c38155be53e0, locale: en, version: 1
      # keeping id: 981824, state: published, updated_at: 2016-08-15 11:20:13 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 981823, state: superseded, updated_at: 2016-08-15 11:20:13 UTC, publishing_app: whitehall, document_type: contact
      { id: 981823, content_id: "bd166f03-2752-4a20-bf43-c38155be53e0", updated_at: "2016-08-15 11:20:13 UTC" },

      # Content item: bd3002a7-119d-4a88-8361-4b1b97701498, locale: en, version: 1
      # keeping id: 994713, state: superseded, updated_at: 2016-08-19 16:02:44 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 994714, state: superseded, updated_at: 2016-08-19 16:02:44 UTC, publishing_app: whitehall, document_type: contact
      { id: 994714, content_id: "bd3002a7-119d-4a88-8361-4b1b97701498", updated_at: "2016-08-19 16:02:44 UTC" },

      # Content item: bd3002a7-119d-4a88-8361-4b1b97701498, locale: en, version: 2
      # keeping id: 995504, state: published, updated_at: 2016-08-22 07:42:29 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 995503, state: superseded, updated_at: 2016-08-22 07:42:29 UTC, publishing_app: whitehall, document_type: contact
      { id: 995503, content_id: "bd3002a7-119d-4a88-8361-4b1b97701498", updated_at: "2016-08-22 07:42:29 UTC" },

      # Content item: beff5ee4-d2ee-4b21-b092-14f470df60dd, locale: en, version: 1
      # keeping id: 971860, state: published, updated_at: 2016-08-09 08:02:56 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 584799, state: superseded, updated_at: 2016-04-13 15:19:44 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 584799, content_id: "beff5ee4-d2ee-4b21-b092-14f470df60dd", updated_at: "2016-04-13 15:19:44 UTC" },

      # Content item: c0b53a42-5406-4689-858f-8fafe9e7ec17, locale: en, version: 2
      # keeping id: 959940, state: superseded, updated_at: 2016-08-03 15:03:40 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 959941, state: superseded, updated_at: 2016-08-03 15:03:40 UTC, publishing_app: whitehall, document_type: contact
      { id: 959941, content_id: "c0b53a42-5406-4689-858f-8fafe9e7ec17", updated_at: "2016-08-03 15:03:40 UTC" },

      # Content item: c0b53a42-5406-4689-858f-8fafe9e7ec17, locale: en, version: 3
      # keeping id: 959944, state: published, updated_at: 2016-08-03 15:04:34 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 959943, state: superseded, updated_at: 2016-08-03 15:04:34 UTC, publishing_app: whitehall, document_type: contact
      { id: 959943, content_id: "c0b53a42-5406-4689-858f-8fafe9e7ec17", updated_at: "2016-08-03 15:04:34 UTC" },

      # Content item: c16cf3a6-f0f0-4b87-afd0-6e876fcdcbe7, locale: en, version: 1
      # keeping id: 848449, state: published, updated_at: 2016-07-13 08:30:12 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 437072, state: superseded, updated_at: 2016-03-07 12:54:58 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 437072, content_id: "c16cf3a6-f0f0-4b87-afd0-6e876fcdcbe7", updated_at: "2016-03-07 12:54:58 UTC" },

      # Content item: c1b1ee02-ab0f-4124-8816-530f3a30051c, locale: hi, version: 4
      # keeping id: 997888, state: published, updated_at: 2016-08-24 06:03:24 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997890, state: draft, updated_at: 2016-08-24 06:03:24 UTC, publishing_app: whitehall, document_type: contact
      { id: 997890, content_id: "c1b1ee02-ab0f-4124-8816-530f3a30051c", updated_at: "2016-08-24 06:03:24 UTC" },

      # Content item: c4e8dc62-78c8-4138-b7e1-3a955fcad1e1, locale: en, version: 1
      # keeping id: 884433, state: published, updated_at: 2016-07-29 15:09:48 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 437977, state: superseded, updated_at: 2016-03-07 12:56:37 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 437977, content_id: "c4e8dc62-78c8-4138-b7e1-3a955fcad1e1", updated_at: "2016-03-07 12:56:37 UTC" },

      # Content item: c6001e6b-e041-47c8-bf96-adc3e8f0e8d3, locale: en, version: 2
      # keeping id: 972896, state: published, updated_at: 2016-08-09 12:29:49 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 972897, state: draft, updated_at: 2016-08-09 12:29:49 UTC, publishing_app: whitehall, document_type: contact
      { id: 972897, content_id: "c6001e6b-e041-47c8-bf96-adc3e8f0e8d3", updated_at: "2016-08-09 12:29:49 UTC" },

      # Content item: c6715211-39a5-476d-b591-0e84f710b44b, locale: en, version: 1
      # keeping id: 854299, state: published, updated_at: 2016-07-19 08:30:23 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 438155, state: superseded, updated_at: 2016-03-07 12:56:56 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 438155, content_id: "c6715211-39a5-476d-b591-0e84f710b44b", updated_at: "2016-03-07 12:56:56 UTC" },

      # Content item: c86c676e-c336-49bb-a9eb-45323d9b8310, locale: en, version: 1
      # keeping id: 977515, state: published, updated_at: 2016-08-11 08:30:20 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 801800, state: superseded, updated_at: 2016-06-08 12:20:50 UTC, publishing_app: whitehall, document_type: official
      { id: 801800, content_id: "c86c676e-c336-49bb-a9eb-45323d9b8310", updated_at: "2016-06-08 12:20:50 UTC" },

      # Content item: ca875f3a-2660-4561-bdd3-4c91a8077647, locale: en, version: 2
      # keeping id: 974924, state: superseded, updated_at: 2016-08-09 14:15:11 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 974925, state: superseded, updated_at: 2016-08-09 14:15:11 UTC, publishing_app: whitehall, document_type: contact
      { id: 974925, content_id: "ca875f3a-2660-4561-bdd3-4c91a8077647", updated_at: "2016-08-09 14:15:11 UTC" },

      # Content item: ca875f3a-2660-4561-bdd3-4c91a8077647, locale: en, version: 3
      # keeping id: 974929, state: published, updated_at: 2016-08-09 14:15:47 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 974928, state: superseded, updated_at: 2016-08-09 14:15:47 UTC, publishing_app: whitehall, document_type: contact
      { id: 974928, content_id: "ca875f3a-2660-4561-bdd3-4c91a8077647", updated_at: "2016-08-09 14:15:47 UTC" },

      # Content item: d28b3542-b627-44ca-9830-28a97f75cdbc, locale: en, version: 1
      # keeping id: 849040, state: published, updated_at: 2016-07-13 12:04:43 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 849041, state: draft, updated_at: 2016-07-13 12:04:43 UTC, publishing_app: whitehall, document_type: contact
      { id: 849041, content_id: "d28b3542-b627-44ca-9830-28a97f75cdbc", updated_at: "2016-07-13 12:04:43 UTC" },

      # Content item: d9fe21f3-704d-4c57-aa27-e621e988e3b1, locale: en, version: 2
      # keeping id: 859772, state: superseded, updated_at: 2016-07-21 09:17:25 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 859773, state: superseded, updated_at: 2016-07-21 09:18:16 UTC, publishing_app: whitehall, document_type: contact
      { id: 859773, content_id: "d9fe21f3-704d-4c57-aa27-e621e988e3b1", updated_at: "2016-07-21 09:18:16 UTC" },

      # Content item: d9fe21f3-704d-4c57-aa27-e621e988e3b1, locale: en, version: 3
      # keeping id: 859774, state: superseded, updated_at: 2016-07-21 09:18:48 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 859775, state: superseded, updated_at: 2016-07-21 09:19:32 UTC, publishing_app: whitehall, document_type: contact
      { id: 859775, content_id: "d9fe21f3-704d-4c57-aa27-e621e988e3b1", updated_at: "2016-07-21 09:19:32 UTC" },

      # Content item: d9fe21f3-704d-4c57-aa27-e621e988e3b1, locale: en, version: 4
      # keeping id: 859784, state: published, updated_at: 2016-07-21 09:20:09 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 859785, state: published, updated_at: 2016-07-21 09:20:09 UTC, publishing_app: whitehall, document_type: contact
      { id: 859785, content_id: "d9fe21f3-704d-4c57-aa27-e621e988e3b1", updated_at: "2016-07-21 09:20:09 UTC" },

      # Content item: d9fe21f3-704d-4c57-aa27-e621e988e3b1, locale: en, version: 5
      # keeping id: 859791, state: draft, updated_at: 2016-07-21 09:30:15 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 859792, state: draft, updated_at: 2016-07-21 09:21:31 UTC, publishing_app: whitehall, document_type: contact
      { id: 859792, content_id: "d9fe21f3-704d-4c57-aa27-e621e988e3b1", updated_at: "2016-07-21 09:21:31 UTC" },

      # Content item: dd4c70c4-9e48-4573-b326-4567f4762117, locale: en, version: 1
      # keeping id: 859688, state: published, updated_at: 2016-07-21 08:31:23 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 440029, state: superseded, updated_at: 2016-03-07 13:00:17 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440029, content_id: "dd4c70c4-9e48-4573-b326-4567f4762117", updated_at: "2016-03-07 13:00:17 UTC" },

      # Content item: e1af19cb-1ab1-4d55-a619-ca9f5f3d2ea4, locale: en, version: 2
      # keeping id: 864952, state: superseded, updated_at: 2016-07-22 08:01:54 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 864953, state: superseded, updated_at: 2016-07-22 08:01:54 UTC, publishing_app: whitehall, document_type: contact
      { id: 864953, content_id: "e1af19cb-1ab1-4d55-a619-ca9f5f3d2ea4", updated_at: "2016-07-22 08:01:54 UTC" },

      # Content item: e1af19cb-1ab1-4d55-a619-ca9f5f3d2ea4, locale: en, version: 3
      # keeping id: 864957, state: published, updated_at: 2016-07-22 08:07:08 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 864958, state: draft, updated_at: 2016-07-22 08:07:08 UTC, publishing_app: whitehall, document_type: contact
      { id: 864958, content_id: "e1af19cb-1ab1-4d55-a619-ca9f5f3d2ea4", updated_at: "2016-07-22 08:07:08 UTC" },

      # Content item: e24d3770-5dc3-4274-a6aa-3a70300d62e9, locale: en, version: 1
      # keeping id: 995364, state: superseded, updated_at: 2016-08-19 16:07:01 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 995366, state: superseded, updated_at: 2016-08-19 16:07:01 UTC, publishing_app: whitehall, document_type: contact
      { id: 995366, content_id: "e24d3770-5dc3-4274-a6aa-3a70300d62e9", updated_at: "2016-08-19 16:07:01 UTC" },

      # Content item: e24d3770-5dc3-4274-a6aa-3a70300d62e9, locale: en, version: 2
      # keeping id: 996143, state: published, updated_at: 2016-08-22 07:45:12 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 996142, state: superseded, updated_at: 2016-08-22 07:45:12 UTC, publishing_app: whitehall, document_type: contact
      { id: 996142, content_id: "e24d3770-5dc3-4274-a6aa-3a70300d62e9", updated_at: "2016-08-22 07:45:12 UTC" },

      # Content item: e6dda44b-eaa8-46bb-9267-dcb9bf5ebf22, locale: en, version: 1
      # keeping id: 859691, state: published, updated_at: 2016-07-21 08:31:25 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 438753, state: superseded, updated_at: 2016-03-07 12:58:00 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 438753, content_id: "e6dda44b-eaa8-46bb-9267-dcb9bf5ebf22", updated_at: "2016-03-07 12:58:00 UTC" },

      # Content item: eec6a0f5-e094-46ee-a1e4-0add97406798, locale: en, version: 1
      # keeping id: 981817, state: published, updated_at: 2016-08-15 11:18:38 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 981818, state: draft, updated_at: 2016-08-15 11:18:38 UTC, publishing_app: whitehall, document_type: contact
      { id: 981818, content_id: "eec6a0f5-e094-46ee-a1e4-0add97406798", updated_at: "2016-08-15 11:18:38 UTC" },

      # Content item: f0a51ca4-2063-4628-a380-44e5b0bd4de7, locale: en, version: 1
      # keeping id: 853372, state: published, updated_at: 2016-07-18 11:29:29 UTC, publishing_app: whitehall, document_type: official
      # deleting id: 436175, state: superseded, updated_at: 2016-03-07 12:53:21 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 436175, content_id: "f0a51ca4-2063-4628-a380-44e5b0bd4de7", updated_at: "2016-03-07 12:53:21 UTC" },

      # Content item: f37f6538-7044-4138-a42c-0c451282ea89, locale: en, version: 2
      # keeping id: 998739, state: superseded, updated_at: 2016-08-24 13:29:03 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 998740, state: superseded, updated_at: 2016-08-24 13:29:03 UTC, publishing_app: whitehall, document_type: contact
      { id: 998740, content_id: "f37f6538-7044-4138-a42c-0c451282ea89", updated_at: "2016-08-24 13:29:03 UTC" },

      # Content item: f37f6538-7044-4138-a42c-0c451282ea89, locale: en, version: 3
      # keeping id: 998757, state: published, updated_at: 2016-08-24 13:33:23 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 998756, state: superseded, updated_at: 2016-08-24 13:33:23 UTC, publishing_app: whitehall, document_type: contact
      { id: 998756, content_id: "f37f6538-7044-4138-a42c-0c451282ea89", updated_at: "2016-08-24 13:33:23 UTC" },

      # Content item: f66e1d8e-c1bf-4e7b-9afc-d1a772b586ff, locale: en, version: 2
      # keeping id: 979371, state: published, updated_at: 2016-08-11 15:15:49 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 979370, state: superseded, updated_at: 2016-08-11 15:15:49 UTC, publishing_app: whitehall, document_type: contact
      { id: 979370, content_id: "f66e1d8e-c1bf-4e7b-9afc-d1a772b586ff", updated_at: "2016-08-11 15:15:49 UTC" },

      # Content item: f9b6789f-5d87-4df4-99f4-0fd85a69d503, locale: en, version: 1
      # keeping id: 845139, state: published, updated_at: 2016-07-12 11:13:47 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 438479, state: superseded, updated_at: 2016-03-07 12:57:31 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 438479, content_id: "f9b6789f-5d87-4df4-99f4-0fd85a69d503", updated_at: "2016-03-07 12:57:31 UTC" },

      # Content item: fa23c0cc-cc24-4d6b-a8d8-05e2796e1ef1, locale: en, version: 1
      # keeping id: 960243, state: published, updated_at: 2016-08-04 08:30:31 UTC, publishing_app: whitehall, document_type: national
      # deleting id: 440302, state: superseded, updated_at: 2016-03-07 13:00:47 UTC, publishing_app: whitehall, document_type: statistics_announcement
      { id: 440302, content_id: "fa23c0cc-cc24-4d6b-a8d8-05e2796e1ef1", updated_at: "2016-03-07 13:00:47 UTC" },

      # Content item: fbc057a9-0581-4780-a9f5-ab5f5f384066, locale: en, version: 1
      # keeping id: 999994, state: published, updated_at: 2016-08-24 15:36:29 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 999993, state: superseded, updated_at: 2016-08-24 15:36:29 UTC, publishing_app: whitehall, document_type: contact
      { id: 999993, content_id: "fbc057a9-0581-4780-a9f5-ab5f5f384066", updated_at: "2016-08-24 15:36:29 UTC" },

      # Content item: fc7aeba2-75b2-4a3b-8435-8f517b221f8b, locale: en, version: 2
      # keeping id: 996900, state: superseded, updated_at: 2016-08-22 15:57:58 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 996901, state: superseded, updated_at: 2016-08-22 15:57:58 UTC, publishing_app: whitehall, document_type: contact
      { id: 996901, content_id: "fc7aeba2-75b2-4a3b-8435-8f517b221f8b", updated_at: "2016-08-22 15:57:58 UTC" },

      # Content item: fc7aeba2-75b2-4a3b-8435-8f517b221f8b, locale: en, version: 3
      # keeping id: 997317, state: published, updated_at: 2016-08-23 10:35:12 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 997316, state: superseded, updated_at: 2016-08-23 10:35:12 UTC, publishing_app: whitehall, document_type: contact
      { id: 997316, content_id: "fc7aeba2-75b2-4a3b-8435-8f517b221f8b", updated_at: "2016-08-23 10:35:12 UTC" },

      # Content item: fde44902-47f5-4d92-ad95-4b655d41d074, locale: en, version: 2
      # keeping id: 998256, state: published, updated_at: 2016-08-24 09:59:55 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 998257, state: draft, updated_at: 2016-08-24 09:59:55 UTC, publishing_app: whitehall, document_type: contact
      { id: 998257, content_id: "fde44902-47f5-4d92-ad95-4b655d41d074", updated_at: "2016-08-24 09:59:55 UTC" },

      # Content item: fefac7f3-880c-4e88-9758-4db77024eb13, locale: en, version: 1
      # keeping id: 877340, state: published, updated_at: 2016-07-28 14:19:42 UTC, publishing_app: whitehall, document_type: contact
      # deleting id: 877339, state: superseded, updated_at: 2016-07-28 14:19:42 UTC, publishing_app: whitehall, document_type: contact
      { id: 877339, content_id: "fefac7f3-880c-4e88-9758-4db77024eb13", updated_at: "2016-07-28 14:19:42 UTC" },
    ]
  end
end
