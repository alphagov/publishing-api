require_relative "helpers/delete_content_item"

class LateAugustBasePathForStateConflicts < ActiveRecord::Migration
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
    Helpers::DeleteContentItem.destroy_supporting_objects(content_item)
    content_item.destroy
  end

  def to_delete
    # This data was pulled using DataHygiene::DuplicateContentItem::BasePathForState
    # from a 2016-08-31 database
    # The items to be deleted are those with a earlier timestamp than those they
    # collide with as the later ones will be in the content stores
    [
      # base_path: /government/case-studies/ebbsfleet, content_store: live
      # keeping id: 1005565, content_id: 5d05ff2b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:20:45 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 197668, content_id: acb5351a-51d9-4bdb-95d1-b96191c86b4f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 197668, content_id: "acb5351a-51d9-4bdb-95d1-b96191c86b4f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/case-studies/national-minimum-wage-campaign-comparisons, content_store: live
      # keeping id: 1006655, content_id: 2929aae8-104c-47f1-b283-8f79d883a440, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:58 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 208749, content_id: 650fee96-d6f2-405d-961a-58df741cf1bb, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 208749, content_id: "650fee96-d6f2-405d-961a-58df741cf1bb", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/case-studies/national-minimum-wage-common-errors, content_store: live
      # keeping id: 1006651, content_id: db11fcd5-9720-4a04-837e-134ea0c92f5d, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:57 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 208763, content_id: 2d9e4247-9355-42dc-aaa2-6adde36bf6a8, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 208763, content_id: "2d9e4247-9355-42dc-aaa2-6adde36bf6a8", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/case-studies/sewing-a-better-future-for-women-in-afghanistan, content_store: live
      # keeping id: 1005670, content_id: 5d8ff752-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:20:52 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 651802, content_id: bf6173e1-5ae3-4ca8-8618-051b7ea5d1b4, state: published, updated_at: 2016-04-29 11:13:44 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 651802, content_id: "bf6173e1-5ae3-4ca8-8618-051b7ea5d1b4", updated_at: "2016-04-29 11:13:44 UTC" },

      # base_path: /government/case-studies/sewing-for-independence-fatimas-story, content_store: live
      # keeping id: 1006578, content_id: f26ba3cd-79cb-4a38-8559-bbc3245924d9, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:53 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 651806, content_id: e40f6446-a0ba-431c-9bb6-215aca718d2d, state: published, updated_at: 2016-04-29 11:14:51 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 651806, content_id: "e40f6446-a0ba-431c-9bb6-215aca718d2d", updated_at: "2016-04-29 11:14:51 UTC" },

      # base_path: /government/case-studies/sle-initial-teacher-training, content_store: live
      # keeping id: 1006130, content_id: 5f184c9c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:22 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 820602, content_id: 261c50c7-c52c-4fe1-b46d-b264fae02bf4, state: published, updated_at: 2016-06-16 14:29:22 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 820602, content_id: "261c50c7-c52c-4fe1-b46d-b264fae02bf4", updated_at: "2016-06-16 14:29:22 UTC" },

      # base_path: /government/case-studies/sle-in-teaching-and-learning-at-a-large-secondary, content_store: live
      # keeping id: 1006127, content_id: 5f184ee9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:22 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 820607, content_id: 0e22b080-2ae4-4c45-a16b-d6294803954d, state: published, updated_at: 2016-06-16 14:32:02 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 820607, content_id: "0e22b080-2ae4-4c45-a16b-d6294803954d", updated_at: "2016-06-16 14:32:02 UTC" },

      # base_path: /government/case-studies/sle-maths-specialism-primary-and-secondary, content_store: live
      # keeping id: 1006125, content_id: 5f184b62-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:22 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 820609, content_id: 65b0c5df-80c2-46d8-8406-c7993e0ba825, state: published, updated_at: 2016-06-16 14:33:24 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 820609, content_id: "65b0c5df-80c2-46d8-8406-c7993e0ba825", updated_at: "2016-06-16 14:33:24 UTC" },

      # base_path: /government/case-studies/sle-specialising-in-primary-literacy, content_store: live
      # keeping id: 1006133, content_id: 5f1850da-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:23 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 820604, content_id: 3cf0e6c3-b309-477d-9fcd-9827b32e498c, state: published, updated_at: 2016-06-16 14:30:39 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 820604, content_id: "3cf0e6c3-b309-477d-9fcd-9827b32e498c", updated_at: "2016-06-16 14:30:39 UTC" },

      # base_path: /government/case-studies/subject-knowledge-enhancement-ripley-teaching-school-alliance, content_store: live
      # keeping id: 1006239, content_id: 5f5295a5-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:29 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 197669, content_id: 1b612940-6815-4f39-b976-f70a6125bedf, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 197669, content_id: "1b612940-6815-4f39-b976-f70a6125bedf", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/case-studies/subject-knowledge-enhancement-st-john-the-baptist-school, content_store: live
      # keeping id: 1006242, content_id: 5f52963f-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:29 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 8675, content_id: 139423cc-2fbf-414e-a82e-194841c161f7, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 8675, content_id: "139423cc-2fbf-414e-a82e-194841c161f7", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/case-studies/we-helped-bcb-international-supply-the-ecuadorian-navy, content_store: live
      # keeping id: 1006244, content_id: 5f52942e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:30 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 197670, content_id: f36d9a48-5453-4da9-b54a-b474d81e462a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 197670, content_id: "f36d9a48-5453-4da9-b54a-b474d81e462a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/case-studies/working-for-the-office-of-the-parliamentary-counsel, content_store: live
      # keeping id: 1006185, content_id: 5f4414e3-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:26 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 817545, content_id: 04d3935e-7aab-4a3e-9e3b-2faacbe75400, state: published, updated_at: 2016-06-13 18:25:16 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 817545, content_id: "04d3935e-7aab-4a3e-9e3b-2faacbe75400", updated_at: "2016-06-13 18:25:16 UTC" },

      # base_path: /government/case-studies/working-with-a-team-of-sles, content_store: live
      # keeping id: 1006364, content_id: 6020f9c4-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: redirect, updated_at: 2016-08-26 14:21:39 UTC, publishing_app: whitehall, document_type: case_study
      # deleting id: 820599, content_id: 8121d68b-a57f-4f19-b198-ae679ebd20f9, state: published, updated_at: 2016-06-16 14:27:56 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 820599, content_id: "8121d68b-a57f-4f19-b198-ae679ebd20f9", updated_at: "2016-06-16 14:27:56 UTC" },

      # base_path: /government/world-location-news/201788.de, content_store: live
      # keeping id: 1004862, content_id: 5ebd3977-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 1004858, content_id: 5ebd3977-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 1004858, content_id: "5ebd3977-7631-11e4-a3cb-005056011aef", updated_at: "2016-08-26 14:15:08 UTC" },

      # base_path: /government/world-location-news/203276.zh-tw, content_store: draft
      # keeping id: 1004882, content_id: 5ec04332-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-08-26 14:15:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 1004881, content_id: 5ec04332-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-08-26 14:15:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 1004881, content_id: "5ec04332-7631-11e4-a3cb-005056011aef", updated_at: "2016-08-26 14:15:09 UTC" },

      # base_path: /government/world-location-news/207015.pt, content_store: live
      # keeping id: 1004883, content_id: 5ec463ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 1004879, content_id: 5ec463ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 1004879, content_id: "5ec463ab-7631-11e4-a3cb-005056011aef", updated_at: "2016-08-26 14:15:09 UTC" },

      # base_path: /government/world-location-news/230454.es-419, content_store: live
      # keeping id: 1005232, content_id: 5f4db46f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 1005228, content_id: 5f4db46f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 1005228, content_id: "5f4db46f-7631-11e4-a3cb-005056011aef", updated_at: "2016-08-26 14:15:35 UTC" },

      # base_path: /government/world-location-news/232909.zh-tw, content_store: live
      # keeping id: 1005276, content_id: 5f53068f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 1005270, content_id: 5f53068f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 1005270, content_id: "5f53068f-7631-11e4-a3cb-005056011aef", updated_at: "2016-08-26 14:15:38 UTC" },

      # base_path: /government/world-location-news/233491.pt, content_store: live
      # keeping id: 1005300, content_id: 5f544de6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 1005294, content_id: 5f544de6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-26 14:15:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 1005294, content_id: "5f544de6-7631-11e4-a3cb-005056011aef", updated_at: "2016-08-26 14:15:39 UTC" },
    ]
  end
end
