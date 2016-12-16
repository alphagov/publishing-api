class ResolveBasePathForStateConflicts < ActiveRecord::Migration
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
    # This data was pulled using DataHygiene::DuplicateContentItem::BasePathForState
    # from a 2016-08-25 database
    # The items to be deleted are those with a earlier timestamp than those they
    # collide with as the later ones will be in the content stores
    [
      # base_path: /asylum-support-tribunal-decisions/xxaa-v-secretary-of-state-for-the-home-department-as-07-07-15572, content_store: draft
      # keeping id: 997211, content_id: ce5f4c90-fa39-4f1f-96fd-83cf00c342bb, state: draft, updated_at: 2016-08-23 09:53:32 UTC, publishing_app: specialist-publisher, document_type: asylum_support_decision
      # deleting id: 997210, content_id: fc69f171-1735-485a-8dc8-ee0b7b4fd0df, state: draft, updated_at: 2016-08-23 09:53:31 UTC, publishing_app: specialist-publisher, document_type: asylum_support_decision, details match item to keep: yes
      { id: 997210, content_id: "fc69f171-1735-485a-8dc8-ee0b7b4fd0df", updated_at: "2016-08-23 09:53:31 UTC" },

      # base_path: /asylum-support-tribunal-decisions/xxsh-v-secretary-of-state-for-the-home-department-as-06-06-13556, content_store: draft
      # keeping id: 997215, content_id: 1e75813e-38b5-4d27-b2f8-159b63ffea99, state: draft, updated_at: 2016-08-23 09:53:32 UTC, publishing_app: specialist-publisher, document_type: asylum_support_decision
      # deleting id: 997213, content_id: faf7b1e4-a0c1-4438-894f-39148676e289, state: draft, updated_at: 2016-08-23 09:53:32 UTC, publishing_app: specialist-publisher, document_type: asylum_support_decision, details match item to keep: no
      { id: 997213, content_id: "faf7b1e4-a0c1-4438-894f-39148676e289", updated_at: "2016-08-23 09:53:32 UTC" },
      # deleting id: 997214, content_id: 5a90d973-e0ec-4c8f-b7fe-05b3aaa7741d, state: draft, updated_at: 2016-08-23 09:53:32 UTC, publishing_app: specialist-publisher, document_type: asylum_support_decision, details match item to keep: yes
      { id: 997214, content_id: "5a90d973-e0ec-4c8f-b7fe-05b3aaa7741d", updated_at: "2016-08-23 09:53:32 UTC" },

      # base_path: /cma-cases/ca98-and-cartels-cases-before-1-april-2014, content_store: live
      # keeping id: 973236, content_id: 567e4e4c-112c-4266-a6e1-78448f5f7abf, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-09 13:30:08 UTC, publishing_app: specialist-publisher, document_type: cma_case
      # deleting id: 48614, content_id: 2244aca5-e6b7-4369-9961-941b300cc985, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 48614, content_id: "2244aca5-e6b7-4369-9961-941b300cc985", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /cma-cases/gtcr-uk-gorkana-merger-inquiry, content_store: live
      # keeping id: 777402, content_id: c04c602e-39cf-4efb-a3f6-58fcf2887262, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-09 13:31:41 UTC, publishing_app: specialist-publisher, document_type: cma_case
      # deleting id: 12921, content_id: 78db695c-0a89-49a4-a660-aed51a38d799, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12921, content_id: "78db695c-0a89-49a4-a660-aed51a38d799", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /cma-cases/merger-cases-before-1-april-2014, content_store: live
      # keeping id: 973240, content_id: 1e23c655-f6b3-4451-8a5b-48d0e7bb7aa0, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-09 13:30:09 UTC, publishing_app: specialist-publisher, document_type: cma_case
      # deleting id: 12960, content_id: 0f2ba366-8eb1-4dc5-b442-6fdfe42faee9, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12960, content_id: "0f2ba366-8eb1-4dc5-b442-6fdfe42faee9", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /done-apply-queens-award-enterprise, content_store: draft
      # keeping id: 832418, content_id: c3cd8556-4a95-4c6d-ab2d-d1f6cd280d37, state: draft, updated_at: 2016-06-28 13:41:00 UTC, publishing_app: publisher, document_type: completed_transaction
      # deleting id: 13146, content_id: 0e4bc22b-ff05-49a1-b837-f18be6fd6bb2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: publisher, document_type: placeholder, details match item to keep: no
      { id: 13146, content_id: "0e4bc22b-ff05-49a1-b837-f18be6fd6bb2", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 226059, content_id: 0e4bc22b-ff05-49a1-b837-f18be6fd6bb2, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: publisher, document_type: placeholder, details match item to keep: no
      { id: 226059, content_id: "0e4bc22b-ff05-49a1-b837-f18be6fd6bb2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-accu-chek-home-use-blood-glucose-meters-falsely-low-blood-glucose-readings, content_store: live
      # keeping id: 999257, content_id: 08083898-83a8-4301-b279-1f853232f1d1, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 12290, content_id: 847aeaa9-d045-481a-9d55-7f3199ba5bb2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12290, content_id: "847aeaa9-d045-481a-9d55-7f3199ba5bb2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-accu-chek-home-use-blood-glucose-meters-may-give-falsely-high-readings, content_store: live
      # keeping id: 999260, content_id: d863f7b1-fdcd-4999-95f1-6a6c0e997d49, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 12291, content_id: 3bf4f0c0-4f53-4058-9064-acef84387337, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12291, content_id: "3bf4f0c0-4f53-4058-9064-acef84387337", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-adaptors-for-shelfpak-humidifier-and-aquapak-sterile-water-risk-of-packaging-not-being-sealed-properly, content_store: live
      # keeping id: 999258, content_id: 917f7cd8-788f-418a-8e23-108f915e2b32, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 139462, content_id: 8cb7c43c-1038-466e-9652-ad09c1239153, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 139462, content_id: "8cb7c43c-1038-466e-9652-ad09c1239153", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-alaris-smartsite-needle-free-valve-risk-of-delay-to-treatment, content_store: live
      # keeping id: 999262, content_id: 4251615b-6459-4ccd-afbe-8a5079b55c9c, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 13165, content_id: 259363f4-df3d-4e52-bf72-8476d46409ae, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 13165, content_id: "259363f4-df3d-4e52-bf72-8476d46409ae", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-basin-bowl-liner-or-equipment-cover-drape-risk-of-small-cracks-or-holes, content_store: live
      # keeping id: 999240, content_id: 7ad92388-5da9-4739-9f3b-889860166390, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:01 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 11661, content_id: fd1b59c5-5145-43f7-b43b-f077caec8d0c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 11661, content_id: "fd1b59c5-5145-43f7-b43b-f077caec8d0c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-gastrostomy-devices-risk-of-infection, content_store: live
      # keeping id: 999243, content_id: 27886cae-b793-427d-8510-17f424ec6a90, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:02 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 11686, content_id: 253bcb4e-fbb9-4589-9cae-9db60a8923e6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 11686, content_id: "253bcb4e-fbb9-4589-9cae-9db60a8923e6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-gel-e-donut-and-squishon-2-neonatal-and-paediatric-support-devices-manufactured-by-philips-healthcare-children-s-medical-ventures-mda-2014-043, content_store: live
      # keeping id: 780214, content_id: 88e0d07d-e399-40c8-8d21-1c92842835cf, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:01 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 11687, content_id: 0a982972-a261-4bff-b828-6aa10ca85f09, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 11687, content_id: "0a982972-a261-4bff-b828-6aa10ca85f09", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-gemstar-infusion-system-risk-of-delay-to-patient-therapy, content_store: live
      # keeping id: 999265, content_id: 327776cb-32b3-4281-b314-113c84aff2d8, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:04 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 12292, content_id: 7d4aa4d5-858c-48dd-9b5c-5133377add0d, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12292, content_id: "7d4aa4d5-858c-48dd-9b5c-5133377add0d", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-insulin-syringe-1ml-safety-syringe-27g-unable-to-deliver-fewer-than-7-units-of-insulin, content_store: live
      # keeping id: 999244, content_id: 232fb075-3435-4add-bbc9-74f5134331b9, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:02 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 11721, content_id: e61f4018-a670-4c83-bb8d-f3f3113307d3, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 11721, content_id: "e61f4018-a670-4c83-bb8d-f3f3113307d3", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-laboratory-reagents-requiring-manual-handling-for-use-in-combination-with-cobas-c-502-analyser, content_store: live
      # keeping id: 999263, content_id: 9368d828-ef65-4363-9b40-a1dad534bd2a, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:04 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 139463, content_id: 1c37a51f-cc28-427c-b092-1972411237f1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 139463, content_id: "1c37a51f-cc28-427c-b092-1972411237f1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-portex-endotracheal-tube-holder-2-5mm-and-3-0mm-manufactured-by-smiths-medical-mda-2014-036, content_store: live
      # keeping id: 999241, content_id: f6abb108-b82d-4fef-829d-63244443c2df, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:01 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 11762, content_id: b6e0af61-23bd-4085-9026-0b26c254db93, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 11762, content_id: "b6e0af61-23bd-4085-9026-0b26c254db93", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-return-7400-and-return-7500-turning-aids-risk-of-injury-due-to-wing-handles-coming-loose, content_store: live
      # keeping id: 999259, content_id: 11618185-c4df-444f-a8c4-dffde744428d, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 12293, content_id: a72943d7-d91a-4f42-83cc-20b41c1058c3, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12293, content_id: "a72943d7-d91a-4f42-83cc-20b41c1058c3", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-reusable-latex-breathing-bags-potential-for-acute-allergic-reactions, content_store: live
      # keeping id: 999261, content_id: 8de3ec89-e099-4c73-a7c2-7c4a110f0e8b, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 7855, content_id: 70a72842-60d7-4331-b56e-952bffe9b7e2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 7855, content_id: "70a72842-60d7-4331-b56e-952bffe9b7e2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-standard-offset-cup-impactor-potential-for-infection, content_store: live
      # keeping id: 999254, content_id: 2d391627-a04d-436b-8faf-a20043906675, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 12294, content_id: 4c4772f3-958d-4630-a18f-d94158ef8230, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12294, content_id: "4c4772f3-958d-4630-a18f-d94158ef8230", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-synthes-trauma-external-fixation-system-change-in-instructions-for-use, content_store: live
      # keeping id: 999255, content_id: 99b9c2a2-2c2a-4f50-b0e2-aa0c4c05d84e, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 12295, content_id: 0815a7d3-5293-4117-aa6b-ac82130e9d2c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12295, content_id: "0815a7d3-5293-4117-aa6b-ac82130e9d2c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /drug-device-alerts/medical-device-alert-ventstar-disposable-breathing-systems-potential-for-loose-adhesive-residue, content_store: live
      # keeping id: 999256, content_id: 427ee4c1-e287-43fd-b093-576f431d2bf7, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-24 15:29:03 UTC, publishing_app: specialist-publisher, document_type: medical_safety_alert
      # deleting id: 12296, content_id: 68bfc600-2b46-44c4-835f-05c54cfa149c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 12296, content_id: "68bfc600-2b46-44c4-835f-05c54cfa149c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /european-structural-investment-funds/don-t-use-sme-support-call-in-greater-cambridge-and-greater-peterborough-oc13r15p-0187, content_store: live
      # keeping id: 976654, content_id: 445f4b03-2be8-47be-8c13-2e6e3fe6e50c, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-10 13:52:00 UTC, publishing_app: specialist-publisher, document_type: esi_fund
      # deleting id: 8329, content_id: 0d25085a-b511-4e1c-ad97-0d9b69e811ac, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 8329, content_id: "0d25085a-b511-4e1c-ad97-0d9b69e811ac", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /european-structural-investment-funds/tourism-business-development-call-in-cumbria-07rd15to0001, content_store: live
      # keeping id: 412545, content_id: fe4acdf5-30c5-4140-9885-0e7acc120990, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-10 13:51:50 UTC, publishing_app: specialist-publisher, document_type: esi_fund
      # deleting id: 13973, content_id: d3d536d9-95f6-424a-af02-d42421825bf1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 13973, content_id: "d3d536d9-95f6-424a-af02-d42421825bf1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/commissioning-of-hearing-aids-response-to-hearing-links-campaign, content_store: live
      # keeping id: 695872, content_id: 5fdc0db2-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:36:39 UTC, publishing_app: whitehall, document_type: government_response
      # deleting id: 301553, content_id: b47a986b-f66d-4a2a-9eb6-31060e738098, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 301553, content_id: "b47a986b-f66d-4a2a-9eb6-31060e738098", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 86583, content_id: b47a986b-f66d-4a2a-9eb6-31060e738098, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 86583, content_id: "b47a986b-f66d-4a2a-9eb6-31060e738098", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/new-proposals-to-tackle-late-payment, content_store: draft
      # keeping id: 700383, content_id: 69b2f25b-6681-41d7-b46b-eabbac54073c, state: draft, updated_at: 2016-05-13 17:13:57 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 42034, content_id: 28f33da3-3340-45df-9cf9-8bf4e4284c4d, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42034, content_id: "28f33da3-3340-45df-9cf9-8bf4e4284c4d", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 257230, content_id: 28f33da3-3340-45df-9cf9-8bf4e4284c4d, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 257230, content_id: "28f33da3-3340-45df-9cf9-8bf4e4284c4d", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-and-around-the-m25-weekly-summary-for-monday-10-november-sunday-16-november, content_store: live
      # keeping id: 699321, content_id: 602d4a1f-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:28 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309411, content_id: 81fe41bc-4e3b-4ef6-8b23-19c064d77e79, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309411, content_id: "81fe41bc-4e3b-4ef6-8b23-19c064d77e79", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94431, content_id: 81fe41bc-4e3b-4ef6-8b23-19c064d77e79, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94431, content_id: "81fe41bc-4e3b-4ef6-8b23-19c064d77e79", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-and-around-the-m25-weekly-summary-for-monday-13-october-sunday-19-october, content_store: live
      # keeping id: 698420, content_id: 6022c2f5-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:54 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309412, content_id: c051ea6b-5ef8-4f2f-8bd2-dcaacc89afef, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309412, content_id: "c051ea6b-5ef8-4f2f-8bd2-dcaacc89afef", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94432, content_id: c051ea6b-5ef8-4f2f-8bd2-dcaacc89afef, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94432, content_id: "c051ea6b-5ef8-4f2f-8bd2-dcaacc89afef", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-and-around-the-m25-weekly-summary-for-monday-17-november-sunday-23-november, content_store: live
      # keeping id: 699802, content_id: 60320b13-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:34 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309414, content_id: 5eb186ea-6035-49cb-a5d5-2680be410479, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309414, content_id: "5eb186ea-6035-49cb-a5d5-2680be410479", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94434, content_id: 5eb186ea-6035-49cb-a5d5-2680be410479, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94434, content_id: "5eb186ea-6035-49cb-a5d5-2680be410479", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-and-around-the-m25-weekly-summary-for-monday-20-october-sunday-26-october, content_store: live
      # keeping id: 698693, content_id: 6024fb04-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:43 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309416, content_id: ccbc6533-fa5e-40d1-9e97-41941f10c5fc, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309416, content_id: "ccbc6533-fa5e-40d1-9e97-41941f10c5fc", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94436, content_id: ccbc6533-fa5e-40d1-9e97-41941f10c5fc, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94436, content_id: "ccbc6533-fa5e-40d1-9e97-41941f10c5fc", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-and-around-the-m25-weekly-summary-for-monday-27-october-sunday-2-november, content_store: live
      # keeping id: 698952, content_id: 6027c58b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:19 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309418, content_id: 6efce832-42ec-4a7b-9908-ce847d1c5d7f, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309418, content_id: "6efce832-42ec-4a7b-9908-ce847d1c5d7f", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94438, content_id: 6efce832-42ec-4a7b-9908-ce847d1c5d7f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94438, content_id: "6efce832-42ec-4a7b-9908-ce847d1c5d7f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-and-around-the-m25-weekly-summary-for-monday-3-november-sunday-9-november, content_store: live
      # keeping id: 699081, content_id: 602a73af-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:06 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309420, content_id: ecc632c3-637c-4f29-9c12-695ebf5aa1e3, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309420, content_id: "ecc632c3-637c-4f29-9c12-695ebf5aa1e3", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94440, content_id: ecc632c3-637c-4f29-9c12-695ebf5aa1e3, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94440, content_id: "ecc632c3-637c-4f29-9c12-695ebf5aa1e3", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-bristol-gloucestershire-somerset-banes-wiltshire-west-dorset-and-devon-weekly-summary-for-monday-10-november-sunday-16-no, content_store: live
      # keeping id: 699333, content_id: 602d5829-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:32 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 412422, content_id: fe9c46d3-0f56-4cc2-9572-6ebc52e5c471, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 412422, content_id: "fe9c46d3-0f56-4cc2-9572-6ebc52e5c471", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 197397, content_id: fe9c46d3-0f56-4cc2-9572-6ebc52e5c471, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 197397, content_id: "fe9c46d3-0f56-4cc2-9572-6ebc52e5c471", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-bristol-gloucestershire-somerset-banes-wiltshire-west-dorset-and-devon-weekly-summary-for-monday-17-november-sunday-23-no, content_store: live
      # keeping id: 699765, content_id: 603196e0-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:15 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 354368, content_id: c89ee87d-8581-47ba-bd0e-6fa4533f3aa5, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 354368, content_id: "c89ee87d-8581-47ba-bd0e-6fa4533f3aa5", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 139483, content_id: c89ee87d-8581-47ba-bd0e-6fa4533f3aa5, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 139483, content_id: "c89ee87d-8581-47ba-bd0e-6fa4533f3aa5", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-bristol-gloucestershire-somerset-banes-wiltshire-west-dorset-and-devon-weekly-summary-for-monday-27-october-sunday-2-nove, content_store: live
      # keeping id: 698959, content_id: 6027cd90-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:23 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 354367, content_id: 67c6197a-4e26-41bb-bfa3-defae603fe62, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 354367, content_id: "67c6197a-4e26-41bb-bfa3-defae603fe62", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 139482, content_id: 67c6197a-4e26-41bb-bfa3-defae603fe62, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 139482, content_id: "67c6197a-4e26-41bb-bfa3-defae603fe62", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-bristol-gloucestershire-somerset-banes-wiltshire-west-dorset-and-devon-weekly-summary-for-monday-3-november-sunday-9-nove, content_store: live
      # keeping id: 699095, content_id: 602aa0eb-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:16 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 296351, content_id: 9b6acf75-8ebc-4782-b2cf-4c955ab35c70, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 296351, content_id: "9b6acf75-8ebc-4782-b2cf-4c955ab35c70", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 81390, content_id: 9b6acf75-8ebc-4782-b2cf-4c955ab35c70, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 81390, content_id: "9b6acf75-8ebc-4782-b2cf-4c955ab35c70", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-bristol-gloucestershire-somerset-banes-wiltshire-west-dorset-weekly-summary-for-monday-20-october-sunday-26-october-2014, content_store: live
      # keeping id: 698701, content_id: 6024ff1c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:45 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258073, content_id: 1f2efca4-3c30-4870-9bb8-b248766cf51e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258073, content_id: "1f2efca4-3c30-4870-9bb8-b248766cf51e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42881, content_id: 1f2efca4-3c30-4870-9bb8-b248766cf51e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42881, content_id: "1f2efca4-3c30-4870-9bb8-b248766cf51e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-central-southern-england-weekly-summary-for-monday-10-sunday-16-november-2014, content_store: live
      # keeping id: 699318, content_id: 602d46d9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:26 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258075, content_id: 6114ab3d-db50-4062-83b2-d8f4fad14af6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258075, content_id: "6114ab3d-db50-4062-83b2-d8f4fad14af6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42883, content_id: 6114ab3d-db50-4062-83b2-d8f4fad14af6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42883, content_id: "6114ab3d-db50-4062-83b2-d8f4fad14af6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-central-southern-england-weekly-summary-for-monday-13-october-sunday-19-october-2014, content_store: live
      # keeping id: 698418, content_id: 6022c207-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:53 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 412275, content_id: 239bcebe-bc1d-43a1-a77a-5ed14e29c96a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 412275, content_id: "239bcebe-bc1d-43a1-a77a-5ed14e29c96a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 197362, content_id: 239bcebe-bc1d-43a1-a77a-5ed14e29c96a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 197362, content_id: "239bcebe-bc1d-43a1-a77a-5ed14e29c96a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-central-southern-england-weekly-summary-for-monday-17-sunday-23-november-2014, content_store: live
      # keeping id: 699801, content_id: 60320ac7-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:34 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258077, content_id: 37057ca4-94c6-4c6c-b0b8-6b77880d90b6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258077, content_id: "37057ca4-94c6-4c6c-b0b8-6b77880d90b6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42885, content_id: 37057ca4-94c6-4c6c-b0b8-6b77880d90b6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42885, content_id: "37057ca4-94c6-4c6c-b0b8-6b77880d90b6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-central-southern-england-weekly-summary-for-monday-20-october-sunday-26-october-2014, content_store: live
      # keeping id: 698694, content_id: 6024fa0e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:43 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 354366, content_id: 83f325a7-ad0e-4fac-b37e-85d724d56b1e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 354366, content_id: "83f325a7-ad0e-4fac-b37e-85d724d56b1e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 139481, content_id: 83f325a7-ad0e-4fac-b37e-85d724d56b1e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 139481, content_id: "83f325a7-ad0e-4fac-b37e-85d724d56b1e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-central-southern-england-weekly-summary-for-monday-27-october-sunday-2-november-2014, content_store: live
      # keeping id: 698911, content_id: 60275359-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:01:53 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 354365, content_id: c45d6453-f41b-464f-97aa-2df4a1f5365a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 354365, content_id: "c45d6453-f41b-464f-97aa-2df4a1f5365a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 139480, content_id: c45d6453-f41b-464f-97aa-2df4a1f5365a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 139480, content_id: "c45d6453-f41b-464f-97aa-2df4a1f5365a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-central-southern-england-weekly-summary-for-monday-3-sunday-9-november-2014, content_store: live
      # keeping id: 699100, content_id: 602aa3f6-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:17 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309451, content_id: 673b135e-6848-4b8f-8268-93b34e811105, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309451, content_id: "673b135e-6848-4b8f-8268-93b34e811105", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94471, content_id: 673b135e-6848-4b8f-8268-93b34e811105, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94471, content_id: "673b135e-6848-4b8f-8268-93b34e811105", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-devon-and-cornwall-weekly-summary-for-monday-17-november-2014-sunday-23-november-2014, content_store: live
      # keeping id: 699763, content_id: 603191c7-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:14 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 412269, content_id: ea5eb862-2b5f-427b-8f2f-225d376c7a57, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 412269, content_id: "ea5eb862-2b5f-427b-8f2f-225d376c7a57", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 197355, content_id: ea5eb862-2b5f-427b-8f2f-225d376c7a57, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 197355, content_id: "ea5eb862-2b5f-427b-8f2f-225d376c7a57", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-devon-and-cornwall-weekly-summary-for-monday-20-october-2014-sunday-27-october-2014, content_store: live
      # keeping id: 698700, content_id: 6024fed0-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:44 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 230646, content_id: 8a6e39b6-3930-4a0a-a8b6-57abdcf390f3, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 230646, content_id: "8a6e39b6-3930-4a0a-a8b6-57abdcf390f3", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 17573, content_id: 8a6e39b6-3930-4a0a-a8b6-57abdcf390f3, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 17573, content_id: "8a6e39b6-3930-4a0a-a8b6-57abdcf390f3", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-devon-and-cornwall-weekly-summary-for-monday-27-october-2014-sunday-2-november-2014--2, content_store: live
      # keeping id: 698957, content_id: 6027cb7d-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:22 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 296350, content_id: 99644a4e-3710-4a9a-935d-92beef6f0785, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 296350, content_id: "99644a4e-3710-4a9a-935d-92beef6f0785", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 81389, content_id: 99644a4e-3710-4a9a-935d-92beef6f0785, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 81389, content_id: "99644a4e-3710-4a9a-935d-92beef6f0785", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-devon-and-cornwall-weekly-summary-for-monday-3-november-2014-sunday-9-november-2014, content_store: live
      # keeping id: 699097, content_id: 602aa1dc-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:16 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 230653, content_id: 6c42d25d-c22f-443e-b4df-042837fd52d1, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 230653, content_id: "6c42d25d-c22f-443e-b4df-042837fd52d1", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 17580, content_id: 6c42d25d-c22f-443e-b4df-042837fd52d1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 17580, content_id: "6c42d25d-c22f-443e-b4df-042837fd52d1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-kent-and-sussex-weekly-summary-for-monday-10-november-sunday-16-november-2014, content_store: live
      # keeping id: 699319, content_id: 602d4859-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:27 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258089, content_id: 36fbffcc-2ef6-440f-a51c-1e0de2a14778, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258089, content_id: "36fbffcc-2ef6-440f-a51c-1e0de2a14778", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42896, content_id: 36fbffcc-2ef6-440f-a51c-1e0de2a14778, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42896, content_id: "36fbffcc-2ef6-440f-a51c-1e0de2a14778", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-kent-and-sussex-weekly-summary-for-monday-13-october-sunday-19-october-2014, content_store: live
      # keeping id: 698419, content_id: 6022c25a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:54 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309462, content_id: fa8f5473-733c-4f26-9f4e-37d326d3f818, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309462, content_id: "fa8f5473-733c-4f26-9f4e-37d326d3f818", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94482, content_id: fa8f5473-733c-4f26-9f4e-37d326d3f818, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94482, content_id: "fa8f5473-733c-4f26-9f4e-37d326d3f818", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-kent-and-sussex-weekly-summary-for-monday-17-november-sunday-23-november-2014, content_store: live
      # keeping id: 699803, content_id: 60320b61-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:34 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258091, content_id: 71e547c7-69b5-4a8c-814d-799c7a6cd525, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258091, content_id: "71e547c7-69b5-4a8c-814d-799c7a6cd525", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42898, content_id: 71e547c7-69b5-4a8c-814d-799c7a6cd525, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42898, content_id: "71e547c7-69b5-4a8c-814d-799c7a6cd525", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-kent-and-sussex-weekly-summary-for-monday-20-october-sunday-26-october-2014, content_store: live
      # keeping id: 698692, content_id: 6024f89e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:42 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309463, content_id: 5dfd24c5-6571-4fca-aa0a-d6287fefc749, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309463, content_id: "5dfd24c5-6571-4fca-aa0a-d6287fefc749", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94483, content_id: 5dfd24c5-6571-4fca-aa0a-d6287fefc749, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94483, content_id: "5dfd24c5-6571-4fca-aa0a-d6287fefc749", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-kent-and-sussex-weekly-summary-for-monday-27-october-sunday-2-november-2014, content_store: live
      # keeping id: 698875, content_id: 6027206f-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:01:38 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309465, content_id: 05fc382c-f9f5-4e01-b6a3-9f59c610eef1, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309465, content_id: "05fc382c-f9f5-4e01-b6a3-9f59c610eef1", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94486, content_id: 05fc382c-f9f5-4e01-b6a3-9f59c610eef1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94486, content_id: "05fc382c-f9f5-4e01-b6a3-9f59c610eef1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-kent-and-sussex-weekly-summary-for-monday-3-november-sunday-9-november-2014, content_store: live
      # keeping id: 699080, content_id: 602a7305-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:06 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309468, content_id: 57ef3a85-713f-457c-8287-23413ff949b9, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309468, content_id: "57ef3a85-713f-457c-8287-23413ff949b9", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94488, content_id: 57ef3a85-713f-457c-8287-23413ff949b9, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94488, content_id: "57ef3a85-713f-457c-8287-23413ff949b9", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-north-east-weekly-summary-for-monday-27th-october-to-sunday-2nd-november-2014, content_store: live
      # keeping id: 698963, content_id: 6027d913-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:27 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309470, content_id: db2566b3-84f4-4148-89a5-ca577e764c37, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309470, content_id: "db2566b3-84f4-4148-89a5-ca577e764c37", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94490, content_id: db2566b3-84f4-4148-89a5-ca577e764c37, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94490, content_id: "db2566b3-84f4-4148-89a5-ca577e764c37", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-midlands-weekly-summary-for-monday-10-november-to-sunday-16-november, content_store: live
      # keeping id: 699324, content_id: 602d4bf1-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:29 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309471, content_id: b6c1b458-d926-4a89-9928-4bc45dad7931, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309471, content_id: "b6c1b458-d926-4a89-9928-4bc45dad7931", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94491, content_id: b6c1b458-d926-4a89-9928-4bc45dad7931, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94491, content_id: "b6c1b458-d926-4a89-9928-4bc45dad7931", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-midlands-weekly-summary-for-monday-17-november-to-sunday-23-november, content_store: live
      # keeping id: 699804, content_id: 60320bad-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:34 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309472, content_id: 00bc9ef6-7608-4104-bf2c-8081d34131f7, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309472, content_id: "00bc9ef6-7608-4104-bf2c-8081d34131f7", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94492, content_id: 00bc9ef6-7608-4104-bf2c-8081d34131f7, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94492, content_id: "00bc9ef6-7608-4104-bf2c-8081d34131f7", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-midlands-weekly-summary-for-monday-20-october-to-sunday-26-october, content_store: live
      # keeping id: 698699, content_id: 6024fe3a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:44 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309473, content_id: fdadc6d3-5ed4-4bb0-8465-f7b898305583, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309473, content_id: "fdadc6d3-5ed4-4bb0-8465-f7b898305583", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94493, content_id: fdadc6d3-5ed4-4bb0-8465-f7b898305583, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94493, content_id: "fdadc6d3-5ed4-4bb0-8465-f7b898305583", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-midlands-weekly-summary-for-monday-27-october-to-sunday-2-november, content_store: live
      # keeping id: 698949, content_id: 6027c41b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:19 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309474, content_id: c0e71bed-f55b-4d68-be08-57f51b631932, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309474, content_id: "c0e71bed-f55b-4d68-be08-57f51b631932", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94494, content_id: c0e71bed-f55b-4d68-be08-57f51b631932, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94494, content_id: "c0e71bed-f55b-4d68-be08-57f51b631932", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-midlands-weekly-summary-for-monday-3-november-to-sunday-9-november, content_store: live
      # keeping id: 699103, content_id: 602aa7e9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:19 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309475, content_id: dad358e8-6b8d-4964-abbf-d1e6324b13e1, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309475, content_id: "dad358e8-6b8d-4964-abbf-d1e6324b13e1", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94496, content_id: dad358e8-6b8d-4964-abbf-d1e6324b13e1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94496, content_id: "dad358e8-6b8d-4964-abbf-d1e6324b13e1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-of-england-weekly-summary-for-monday-10-sunday-16-november-2014, content_store: live
      # keeping id: 699334, content_id: 602d58d1-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:32 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258102, content_id: 62b4c6d8-5126-4c31-86c8-aa9b051a5598, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258102, content_id: "62b4c6d8-5126-4c31-86c8-aa9b051a5598", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42908, content_id: 62b4c6d8-5126-4c31-86c8-aa9b051a5598, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42908, content_id: "62b4c6d8-5126-4c31-86c8-aa9b051a5598", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-of-england-weekly-summary-for-monday-13-sunday-19-october-2014, content_store: live
      # keeping id: 698408, content_id: 6022a824-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:47 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258104, content_id: 344cbcca-5345-4cf9-835e-8a448db3eec7, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258104, content_id: "344cbcca-5345-4cf9-835e-8a448db3eec7", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42910, content_id: 344cbcca-5345-4cf9-835e-8a448db3eec7, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42910, content_id: "344cbcca-5345-4cf9-835e-8a448db3eec7", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-of-england-weekly-summary-for-monday-17-sunday-23-november-2014, content_store: live
      # keeping id: 699764, content_id: 60319646-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:14 UTC, publishing_app: whitehall, document_type: news_story
      # deleting id: 258108, content_id: 7fbde54c-c886-4f24-afdb-186dd1aa29dd, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258108, content_id: "7fbde54c-c886-4f24-afdb-186dd1aa29dd", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42914, content_id: 7fbde54c-c886-4f24-afdb-186dd1aa29dd, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42914, content_id: "7fbde54c-c886-4f24-afdb-186dd1aa29dd", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-of-england-weekly-summary-for-monday-20-sunday-27-october-2014, content_store: live
      # keeping id: 698696, content_id: 6024fc34-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:43 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309482, content_id: a25e77c1-3cf3-4717-b33c-71c08af462f7, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309482, content_id: "a25e77c1-3cf3-4717-b33c-71c08af462f7", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94503, content_id: a25e77c1-3cf3-4717-b33c-71c08af462f7, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94503, content_id: "a25e77c1-3cf3-4717-b33c-71c08af462f7", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-east-of-england-weekly-summary-for-monday-28-october-sunday-2-november-2014, content_store: live
      # keeping id: 698961, content_id: 6027d079-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:24 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 365708, content_id: c1a66d79-6273-4b21-a387-2ca7a8a0cc2c, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 365708, content_id: "c1a66d79-6273-4b21-a387-2ca7a8a0cc2c", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 150839, content_id: c1a66d79-6273-4b21-a387-2ca7a8a0cc2c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 150839, content_id: "c1a66d79-6273-4b21-a387-2ca7a8a0cc2c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-north-west-summary-for-monday-10-to-sunday-16-november, content_store: live
      # keeping id: 699332, content_id: 602d5731-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:32 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258122, content_id: ab253964-923c-4a95-b58f-90870070e9d5, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258122, content_id: "ab253964-923c-4a95-b58f-90870070e9d5", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42929, content_id: ab253964-923c-4a95-b58f-90870070e9d5, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42929, content_id: "ab253964-923c-4a95-b58f-90870070e9d5", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-north-west-summary-for-monday-17-to-sunday-23-november, content_store: live
      # keeping id: 699713, content_id: 60312363-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:09:54 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258126, content_id: e6422b66-83f5-4661-bff2-87e9a19d84ad, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258126, content_id: "e6422b66-83f5-4661-bff2-87e9a19d84ad", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42932, content_id: e6422b66-83f5-4661-bff2-87e9a19d84ad, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42932, content_id: "e6422b66-83f5-4661-bff2-87e9a19d84ad", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-north-west-summary-for-monday-27-october-to-sunday-2-november, content_store: live
      # keeping id: 698950, content_id: 6027c467-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:19 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 365716, content_id: 30b77075-5d86-4d84-8536-e2ea39a8a88d, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 365716, content_id: "30b77075-5d86-4d84-8536-e2ea39a8a88d", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 150848, content_id: 30b77075-5d86-4d84-8536-e2ea39a8a88d, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 150848, content_id: "30b77075-5d86-4d84-8536-e2ea39a8a88d", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-north-west-summary-for-monday-3-to-sunday-9-november, content_store: live
      # keeping id: 699076, content_id: 602a6d51-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:05 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258128, content_id: 50070035-af31-4941-a380-daf25b5c4d60, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258128, content_id: "50070035-af31-4941-a380-daf25b5c4d60", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42934, content_id: 50070035-af31-4941-a380-daf25b5c4d60, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42934, content_id: "50070035-af31-4941-a380-daf25b5c4d60", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-north-west-weekly-summary-for-monday-13-to-sunday-19-october, content_store: live
      # keeping id: 698417, content_id: 6022c1ba-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:53 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309512, content_id: 402a87ed-3012-429e-8ce3-f4c7da37345c, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309512, content_id: "402a87ed-3012-429e-8ce3-f4c7da37345c", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94532, content_id: 402a87ed-3012-429e-8ce3-f4c7da37345c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94532, content_id: "402a87ed-3012-429e-8ce3-f4c7da37345c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-the-north-west-weekly-summary-for-monday-20-to-sunday-26-october, content_store: live
      # keeping id: 698534, content_id: 602461bb-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:13 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 365717, content_id: 585fde6d-633d-474b-8d92-909c46ddad7c, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 365717, content_id: "585fde6d-633d-474b-8d92-909c46ddad7c", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 150849, content_id: 585fde6d-633d-474b-8d92-909c46ddad7c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 150849, content_id: "585fde6d-633d-474b-8d92-909c46ddad7c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-road-works-in-west-midlands-weekly-summary-for-monday-10-november-to-16-november-2014, content_store: live
      # keeping id: 699335, content_id: 602d596f-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:33 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309402, content_id: 43b5454e-58a3-40e4-a16b-11a2c186ac44, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309402, content_id: "43b5454e-58a3-40e4-a16b-11a2c186ac44", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94422, content_id: 43b5454e-58a3-40e4-a16b-11a2c186ac44, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94422, content_id: "43b5454e-58a3-40e4-a16b-11a2c186ac44", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-road-works-in-west-midlands-weekly-summary-for-monday-13-to-19-october-2014, content_store: live
      # keeping id: 698422, content_id: 6022c82d-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:54 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 365640, content_id: 45d7f86c-1666-46c8-a545-52535baa3396, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 365640, content_id: "45d7f86c-1666-46c8-a545-52535baa3396", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 150770, content_id: 45d7f86c-1666-46c8-a545-52535baa3396, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 150770, content_id: "45d7f86c-1666-46c8-a545-52535baa3396", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-road-works-in-west-midlands-weekly-summary-for-monday-17-november-to-sunday-23-november, content_store: live
      # keeping id: 699766, content_id: 60319845-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:15 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309404, content_id: 21d1b8e0-6409-46e8-89e4-a2a0a88f9e09, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309404, content_id: "21d1b8e0-6409-46e8-89e4-a2a0a88f9e09", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94424, content_id: 21d1b8e0-6409-46e8-89e4-a2a0a88f9e09, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94424, content_id: "21d1b8e0-6409-46e8-89e4-a2a0a88f9e09", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-road-works-in-west-midlands-weekly-summary-for-monday-20-to-sunday-26-october-2014, content_store: live
      # keeping id: 698687, content_id: 6024f355-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:41 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 365643, content_id: 2591d695-1a83-40d9-a6d3-f58577a6e838, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 365643, content_id: "2591d695-1a83-40d9-a6d3-f58577a6e838", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 150774, content_id: 2591d695-1a83-40d9-a6d3-f58577a6e838, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 150774, content_id: "2591d695-1a83-40d9-a6d3-f58577a6e838", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-road-works-in-west-midlands-weekly-summary-for-monday-27-october-to-2-november-2014, content_store: live
      # keeping id: 698951, content_id: 6027c4af-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:19 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309406, content_id: 5ce2926e-3805-4170-b196-955fe2ae6ca1, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309406, content_id: "5ce2926e-3805-4170-b196-955fe2ae6ca1", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94426, content_id: 5ce2926e-3805-4170-b196-955fe2ae6ca1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94426, content_id: "5ce2926e-3805-4170-b196-955fe2ae6ca1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-road-works-in-west-midlands-weekly-summary-for-monday-3-november-to-9-november-2014, content_store: live
      # keeping id: 699102, content_id: 602aa749-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:19 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 309407, content_id: 69281ad2-6902-4ffe-bfc6-cbefe48cf72e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 309407, content_id: "69281ad2-6902-4ffe-bfc6-cbefe48cf72e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 94427, content_id: 69281ad2-6902-4ffe-bfc6-cbefe48cf72e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 94427, content_id: "69281ad2-6902-4ffe-bfc6-cbefe48cf72e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-yorkshire-and-the-humber-weekly-summary-for-monday-10-november-to-sunday-16-november, content_store: live
      # keeping id: 699273, content_id: 602cce4c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:06:00 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 230742, content_id: 25bcebc4-c9ec-4a76-a3c0-d96cb5e13cf6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 230742, content_id: "25bcebc4-c9ec-4a76-a3c0-d96cb5e13cf6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 17667, content_id: 25bcebc4-c9ec-4a76-a3c0-d96cb5e13cf6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 17667, content_id: "25bcebc4-c9ec-4a76-a3c0-d96cb5e13cf6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-yorkshire-and-the-humber-weekly-summary-for-monday-13-october-to-sunday-19-october, content_store: live
      # keeping id: 698407, content_id: 6022a40b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:46 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 365723, content_id: becc677c-b6bc-4a0d-a696-6433ed39e3d2, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 365723, content_id: "becc677c-b6bc-4a0d-a696-6433ed39e3d2", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 150855, content_id: becc677c-b6bc-4a0d-a696-6433ed39e3d2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 150855, content_id: "becc677c-b6bc-4a0d-a696-6433ed39e3d2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-yorkshire-and-the-humber-weekly-summary-for-monday-17-november-to-sunday-23-november, content_store: live
      # keeping id: 699767, content_id: 603198b9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:10:15 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 230748, content_id: 2c684ea5-296e-4456-90da-24005e40822a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 230748, content_id: "2c684ea5-296e-4456-90da-24005e40822a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 17673, content_id: 2c684ea5-296e-4456-90da-24005e40822a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 17673, content_id: "2c684ea5-296e-4456-90da-24005e40822a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-yorkshire-and-the-humber-weekly-summary-for-monday-20-october-to-sunday-26-october, content_store: live
      # keeping id: 698702, content_id: 6024ffbb-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:45 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258134, content_id: ca18633d-01ae-4c6f-83ae-a7351e7887b6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258134, content_id: "ca18633d-01ae-4c6f-83ae-a7351e7887b6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42940, content_id: ca18633d-01ae-4c6f-83ae-a7351e7887b6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42940, content_id: "ca18633d-01ae-4c6f-83ae-a7351e7887b6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-yorkshire-and-the-humber-weekly-summary-for-monday-27-october-to-sunday-2-november, content_store: live
      # keeping id: 698910, content_id: 6027526c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:01:53 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258135, content_id: f3eb0238-90af-4933-bd03-4615a5acad47, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258135, content_id: "f3eb0238-90af-4933-bd03-4615a5acad47", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42941, content_id: f3eb0238-90af-4933-bd03-4615a5acad47, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42941, content_id: "f3eb0238-90af-4933-bd03-4615a5acad47", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/planned-roadworks-in-yorkshire-and-the-humber-weekly-summary-for-monday-3-november-to-sunday-9-november, content_store: live
      # keeping id: 699050, content_id: 602a0506-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:03:42 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 258136, content_id: b389356b-d71c-452e-af7f-44f3ff5a0f5f, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 258136, content_id: "b389356b-d71c-452e-af7f-44f3ff5a0f5f", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 42942, content_id: b389356b-d71c-452e-af7f-44f3ff5a0f5f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 42942, content_id: "b389356b-d71c-452e-af7f-44f3ff5a0f5f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/traffic-bulletin-closures-on-a1-at-black-cat-as-improvement-work-continues, content_store: live
      # keeping id: 698771, content_id: 6025da04-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:33 UTC, publishing_app: whitehall, document_type: press_release
      # deleting id: 260468, content_id: b7fad29c-4324-4a05-bf48-52fb40f36b53, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 260468, content_id: "b7fad29c-4324-4a05-bf48-52fb40f36b53", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 45271, content_id: b7fad29c-4324-4a05-bf48-52fb40f36b53, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 45271, content_id: "b7fad29c-4324-4a05-bf48-52fb40f36b53", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/news/we-are-recruiting-lawyers, content_store: live
      # keeping id: 698235, content_id: 6020f894-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:16 UTC, publishing_app: whitehall, document_type: news_story
      # deleting id: 314002, content_id: 9a63b2c7-364e-47d7-910b-1e610aaaea4e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 314002, content_id: "9a63b2c7-364e-47d7-910b-1e610aaaea4e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 99015, content_id: 9a63b2c7-364e-47d7-910b-1e610aaaea4e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 99015, content_id: "9a63b2c7-364e-47d7-910b-1e610aaaea4e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/organisations/companies-house/about/access-and-opening, content_store: live
      # keeping id: 998408, content_id: 602aeccf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-24 11:17:41 UTC, publishing_app: whitehall, document_type: access_and_opening
      # deleting id: 681303, content_id: e67a7a84-4aa1-45e2-b4a9-964fc2041e6f, state: published, updated_at: 2016-05-13 13:04:39 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681303, content_id: "e67a7a84-4aa1-45e2-b4a9-964fc2041e6f", updated_at: "2016-05-13 13:04:39 UTC" },

      # base_path: /government/organisations/department-for-transport/about/welsh-language-scheme, content_store: live
      # keeping id: 692467, content_id: 5f54d009-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:27 UTC, publishing_app: whitehall, document_type: welsh_language_scheme
      # deleting id: 681273, content_id: 238b5b32-1060-4d04-ade3-4d46e7416082, state: published, updated_at: 2016-05-13 13:04:34 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681273, content_id: "238b5b32-1060-4d04-ade3-4d46e7416082", updated_at: "2016-05-13 13:04:34 UTC" },

      # base_path: /government/organisations/land-registry/about/about-our-services, content_store: live
      # keeping id: 871422, content_id: 6022603e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-07-28 09:34:41 UTC, publishing_app: whitehall, document_type: about_our_services
      # deleting id: 681211, content_id: 17de8284-ce97-44cd-8559-9cb72bd88043, state: published, updated_at: 2016-05-13 13:04:26 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681211, content_id: "17de8284-ce97-44cd-8559-9cb72bd88043", updated_at: "2016-05-13 13:04:26 UTC" },

      # base_path: /government/organisations/land-registry/about/access-and-opening, content_store: live
      # keeping id: 871321, content_id: 5fe4f554-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-07-28 09:08:39 UTC, publishing_app: whitehall, document_type: access_and_opening
      # deleting id: 681245, content_id: 5c7bbcac-ed0c-4af0-ba7a-52b0ccb0c44e, state: published, updated_at: 2016-05-13 13:04:30 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681245, content_id: "5c7bbcac-ed0c-4af0-ba7a-52b0ccb0c44e", updated_at: "2016-05-13 13:04:30 UTC" },

      # base_path: /government/organisations/land-registry/about/complaints-procedure, content_store: live
      # keeping id: 871425, content_id: 5fe611aa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-07-28 09:35:54 UTC, publishing_app: whitehall, document_type: complaints_procedure
      # deleting id: 681215, content_id: 331416d5-7a86-4c3c-8058-6e4b8493603c, state: published, updated_at: 2016-05-13 13:04:26 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681215, content_id: "331416d5-7a86-4c3c-8058-6e4b8493603c", updated_at: "2016-05-13 13:04:26 UTC" },

      # base_path: /government/organisations/land-registry/about/publication-scheme, content_store: live
      # keeping id: 715765, content_id: 602278fe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-17 11:23:41 UTC, publishing_app: whitehall, document_type: publication_scheme
      # deleting id: 681388, content_id: e667dafa-1517-4440-9df8-79ad73ab1ef7, state: published, updated_at: 2016-05-13 13:04:53 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681388, content_id: "e667dafa-1517-4440-9df8-79ad73ab1ef7", updated_at: "2016-05-13 13:04:53 UTC" },

      # base_path: /government/organisations/land-registry/about/recruitment, content_store: live
      # keeping id: 997008, content_id: 5fe3cc51-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-08-23 08:23:34 UTC, publishing_app: whitehall, document_type: recruitment
      # deleting id: 681350, content_id: ca17a117-8f52-4017-85bd-0f92fa3c78ec, state: published, updated_at: 2016-05-13 13:04:46 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681350, content_id: "ca17a117-8f52-4017-85bd-0f92fa3c78ec", updated_at: "2016-05-13 13:04:46 UTC" },

      # base_path: /government/organisations/land-registry/about/welsh-language-scheme, content_store: live
      # keeping id: 821949, content_id: 5fe3ca99-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-06-20 10:58:12 UTC, publishing_app: whitehall, document_type: welsh_language_scheme
      # deleting id: 681163, content_id: 8bf8c5ea-434c-4a01-8f51-acb571f81590, state: published, updated_at: 2016-05-13 13:04:09 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681163, content_id: "8bf8c5ea-434c-4a01-8f51-acb571f81590", updated_at: "2016-05-13 13:04:09 UTC" },

      # base_path: /government/organisations/office-of-the-public-guardian/about/complaints-procedure, content_store: live
      # keeping id: 876552, content_id: 5fa9e552-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-07-28 12:45:35 UTC, publishing_app: whitehall, document_type: complaints_procedure
      # deleting id: 681243, content_id: 9f5829cb-416a-460c-8057-e434bd41c96c, state: published, updated_at: 2016-05-13 13:04:29 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681243, content_id: "9f5829cb-416a-460c-8057-e434bd41c96c", updated_at: "2016-05-13 13:04:29 UTC" },

      # base_path: /government/people/cashel-gleeson, content_store: live
      # keeping id: 819184, content_id: 63cb1e5f-ed92-4512-96b7-00e34997921c, state: published, updated_at: 2016-06-15 08:57:52 UTC, publishing_app: whitehall, document_type: person
      # deleting id: 819173, content_id: 875005e5-5709-4a8f-848d-f7023e9dfde0, state: superseded, updated_at: 2016-06-15 08:50:08 UTC, publishing_app: whitehall, document_type: person, details match item to keep: yes
      { id: 819173, content_id: "875005e5-5709-4a8f-848d-f7023e9dfde0", updated_at: "2016-06-15 08:50:08 UTC" },
      # deleting id: 819159, content_id: 875005e5-5709-4a8f-848d-f7023e9dfde0, state: superseded, updated_at: 2016-06-15 08:40:08 UTC, publishing_app: whitehall, document_type: person, details match item to keep: yes
      { id: 819159, content_id: "875005e5-5709-4a8f-848d-f7023e9dfde0", updated_at: "2016-06-15 08:40:08 UTC" },
      # deleting id: 819155, content_id: 875005e5-5709-4a8f-848d-f7023e9dfde0, state: superseded, updated_at: 2016-06-15 08:39:22 UTC, publishing_app: whitehall, document_type: person, details match item to keep: yes
      { id: 819155, content_id: "875005e5-5709-4a8f-848d-f7023e9dfde0", updated_at: "2016-06-15 08:39:22 UTC" },
      # deleting id: 819178, content_id: 875005e5-5709-4a8f-848d-f7023e9dfde0, state: unpublished, unpublishing_type: gone, updated_at: 2016-06-15 08:51:37 UTC, publishing_app: whitehall, document_type: person, details match item to keep: yes
      { id: 819178, content_id: "875005e5-5709-4a8f-848d-f7023e9dfde0", updated_at: "2016-06-15 08:51:37 UTC" },

      # base_path: /government/publications/16-to-19-bursary-fund-mi-return-for-2013-to-2014, content_store: live
      # keeping id: 696898, content_id: 5fe9aad2-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:44:38 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 372721, content_id: d76022fa-d97e-44ff-9427-8f4f7e65b8f9, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 372721, content_id: "d76022fa-d97e-44ff-9427-8f4f7e65b8f9", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 157851, content_id: d76022fa-d97e-44ff-9427-8f4f7e65b8f9, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 157851, content_id: "d76022fa-d97e-44ff-9427-8f4f7e65b8f9", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/b16-8ha-ec-harris-uk-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698133, content_id: 601fdf8a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:19 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 265467, content_id: 03ad7f40-1ed2-4c10-bd33-80c76d183e70, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 265467, content_id: "03ad7f40-1ed2-4c10-bd33-80c76d183e70", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 50320, content_id: 03ad7f40-1ed2-4c10-bd33-80c76d183e70, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 50320, content_id: "03ad7f40-1ed2-4c10-bd33-80c76d183e70", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/b69-3el-innovative-environmental-solutions-uk-limited-environmental-permit-draft-decision-advertisement, content_store: live
      # keeping id: 698964, content_id: 6027dc21-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:28 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 317779, content_id: a6587071-53ef-4582-9ee3-71dd83d6d42d, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 317779, content_id: "a6587071-53ef-4582-9ee3-71dd83d6d42d", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 102778, content_id: a6587071-53ef-4582-9ee3-71dd83d6d42d, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 102778, content_id: "a6587071-53ef-4582-9ee3-71dd83d6d42d", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ba1-8hq-wolfe-securities-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698770, content_id: 6025d8d0-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:33 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 317788, content_id: 2d2e5bb7-c442-4bb4-bcb4-c0f371cf725e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 317788, content_id: "2d2e5bb7-c442-4bb4-bcb4-c0f371cf725e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 102787, content_id: 2d2e5bb7-c442-4bb4-bcb4-c0f371cf725e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 102787, content_id: "2d2e5bb7-c442-4bb4-bcb4-c0f371cf725e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ba2-7dg-mr-david-curwen-mr-james-mcphee-mr-jeffery-savage-mr-patrick-dawson-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698531, content_id: 60245d3b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:11 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 317791, content_id: 27129ebf-f530-4159-ae1c-3d22133072cc, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 317791, content_id: "27129ebf-f530-4159-ae1c-3d22133072cc", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 102791, content_id: 27129ebf-f530-4159-ae1c-3d22133072cc, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 102791, content_id: "27129ebf-f530-4159-ae1c-3d22133072cc", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ba3-4dw-rm-penny-plant-hire-and-demolition-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698500, content_id: 6023bf22-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:40 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 265477, content_id: 45338c4b-c534-41c4-b5ef-3c0e69d21e9f, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 265477, content_id: "45338c4b-c534-41c4-b5ef-3c0e69d21e9f", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 50330, content_id: 45338c4b-c534-41c4-b5ef-3c0e69d21e9f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 50330, content_id: "45338c4b-c534-41c4-b5ef-3c0e69d21e9f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/bathing-waters-2013-projected-classifications-in-england, content_store: live
      # keeping id: 688211, content_id: 5ebe3de7-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:25:24 UTC, publishing_app: whitehall, document_type: policy_paper
      # deleting id: 265534, content_id: f945259d-cec6-42ac-b5e9-1fde31179ee8, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 265534, content_id: "f945259d-cec6-42ac-b5e9-1fde31179ee8", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 50390, content_id: f945259d-cec6-42ac-b5e9-1fde31179ee8, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 50390, content_id: "f945259d-cec6-42ac-b5e9-1fde31179ee8", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/bb3-0rp-sita-uk-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698162, content_id: 60204d0a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:39 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 374858, content_id: 01050480-09e1-4ca9-80c5-549b33657304, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 374858, content_id: "01050480-09e1-4ca9-80c5-549b33657304", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 159988, content_id: 01050480-09e1-4ca9-80c5-549b33657304, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 159988, content_id: "01050480-09e1-4ca9-80c5-549b33657304", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/bb7-4qf-castle-cement-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698785, content_id: 6025fd40-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:39 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 317903, content_id: a8508879-71b6-49d9-be05-63710b593420, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 317903, content_id: "a8508879-71b6-49d9-be05-63710b593420", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 102901, content_id: a8508879-71b6-49d9-be05-63710b593420, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 102901, content_id: "a8508879-71b6-49d9-be05-63710b593420", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/bl5-2dl-mrs-m-entwistle-mr-j-entwistle-mr-d-entwistle-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698129, content_id: 601fd892-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:18 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 265708, content_id: 7e3734e1-c0ac-49b2-a2c0-79e319ef8859, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 265708, content_id: "7e3734e1-c0ac-49b2-a2c0-79e319ef8859", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 50563, content_id: 7e3734e1-c0ac-49b2-a2c0-79e319ef8859, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 50563, content_id: "7e3734e1-c0ac-49b2-a2c0-79e319ef8859", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/breedon-aggregates-england-limited-application-made-to-abstract-take-water, content_store: live
      # keeping id: 698510, content_id: 6023dbc6-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:48 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 375474, content_id: a850c230-6111-4ef5-ae67-be559aaf59bb, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 375474, content_id: "a850c230-6111-4ef5-ae67-be559aaf59bb", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 160590, content_id: a850c230-6111-4ef5-ae67-be559aaf59bb, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 160590, content_id: "a850c230-6111-4ef5-ae67-be559aaf59bb", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/bs25-1qp-mr-john-goodwin-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698488, content_id: 602396f4-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:35 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 265983, content_id: bb3b3784-337b-4727-a06e-e7f6f362b476, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 265983, content_id: "bb3b3784-337b-4727-a06e-e7f6f362b476", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 50827, content_id: bb3b3784-337b-4727-a06e-e7f6f362b476, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 50827, content_id: "bb3b3784-337b-4727-a06e-e7f6f362b476", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/burghley-house-preservation-trust-limited-application-made-to-abstract-take-water, content_store: live
      # keeping id: 698385, content_id: 60225e3d-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:32 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 318601, content_id: d5c7caae-c70c-488e-a89b-ee456d71f042, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 318601, content_id: "d5c7caae-c70c-488e-a89b-ee456d71f042", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 103624, content_id: d5c7caae-c70c-488e-a89b-ee456d71f042, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 103624, content_id: "d5c7caae-c70c-488e-a89b-ee456d71f042", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ca1-3nq-h2-energy-esco-33-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698279, content_id: 602141f6-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:31 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 375791, content_id: 7859f008-7211-47b4-9dc8-e4991ab20923, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 375791, content_id: "7859f008-7211-47b4-9dc8-e4991ab20923", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 160907, content_id: 7859f008-7211-47b4-9dc8-e4991ab20923, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 160907, content_id: "7859f008-7211-47b4-9dc8-e4991ab20923", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ch62-3nl-riverside-aggregates-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698165, content_id: 60204e7c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:40 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 266432, content_id: f2618c72-6611-4d5c-9bf1-04bd84f8f4db, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 266432, content_id: "f2618c72-6611-4d5c-9bf1-04bd84f8f4db", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 51274, content_id: f2618c72-6611-4d5c-9bf1-04bd84f8f4db, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 51274, content_id: "f2618c72-6611-4d5c-9bf1-04bd84f8f4db", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/co6-3rn-edward-drake-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698222, content_id: 6020de9a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:10 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 319941, content_id: a9de48a8-0cc8-4ac0-9845-7fe4315f104a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 319941, content_id: "a9de48a8-0cc8-4ac0-9845-7fe4315f104a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 104951, content_id: a9de48a8-0cc8-4ac0-9845-7fe4315f104a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 104951, content_id: "a9de48a8-0cc8-4ac0-9845-7fe4315f104a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/code-of-practice-on-noise-from-audible-intruder-alarms-1982, content_store: live
      # keeping id: 683057, content_id: 5d3892a4-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 13:54:32 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 377121, content_id: c372a952-b294-44a7-a4cf-67823c14d7f6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 377121, content_id: "c372a952-b294-44a7-a4cf-67823c14d7f6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 162235, content_id: c372a952-b294-44a7-a4cf-67823c14d7f6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 162235, content_id: "c372a952-b294-44a7-a4cf-67823c14d7f6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/cr4-4na-riverside-ad-limited-environmental-permit-draft-decision-advertisement, content_store: live
      # keeping id: 698915, content_id: 60275e3d-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:01:55 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 320935, content_id: 82cde757-995b-4d50-a99b-afa8a1fcb7f0, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 320935, content_id: "82cde757-995b-4d50-a99b-afa8a1fcb7f0", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 105948, content_id: 82cde757-995b-4d50-a99b-afa8a1fcb7f0, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 105948, content_id: "82cde757-995b-4d50-a99b-afa8a1fcb7f0", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ct3-4hq-veolia-environmental-services-uk-plc-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698288, content_id: 60214ca9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:35 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 321191, content_id: 53b4e25b-2186-4b53-8d71-eaef37fdf145, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 321191, content_id: "53b4e25b-2186-4b53-8d71-eaef37fdf145", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 106205, content_id: 53b4e25b-2186-4b53-8d71-eaef37fdf145, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 106205, content_id: "53b4e25b-2186-4b53-8d71-eaef37fdf145", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/cv22-7de-modern-plant-hire-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698711, content_id: 60253864-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:58 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 267877, content_id: cf3d4b9e-2862-4345-80c5-67a786f1e779, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 267877, content_id: "cf3d4b9e-2862-4345-80c5-67a786f1e779", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 52712, content_id: cf3d4b9e-2862-4345-80c5-67a786f1e779, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 52712, content_id: "cf3d4b9e-2862-4345-80c5-67a786f1e779", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/cw11-3pu-hw-martin-waste-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698271, content_id: 602138f1-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:28 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 321309, content_id: 4e8925b2-9a77-4ca0-836f-7c23952cef04, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 321309, content_id: "4e8925b2-9a77-4ca0-836f-7c23952cef04", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 106327, content_id: 4e8925b2-9a77-4ca0-836f-7c23952cef04, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 106327, content_id: "4e8925b2-9a77-4ca0-836f-7c23952cef04", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/da10-0df-independent-water-networks-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698514, content_id: 602409af-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:54 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 378445, content_id: 26532c55-f33b-4f46-b7df-6a3b2c0a6b71, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 378445, content_id: "26532c55-f33b-4f46-b7df-6a3b2c0a6b71", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 163573, content_id: 26532c55-f33b-4f46-b7df-6a3b2c0a6b71, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 163573, content_id: "26532c55-f33b-4f46-b7df-6a3b2c0a6b71", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/dl16-6lq-northumbrian-water-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698738, content_id: 602575ae-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:14 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 322610, content_id: 2523ac3d-4c7e-40ea-a215-cbe5d3325218, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 322610, content_id: "2523ac3d-4c7e-40ea-a215-cbe5d3325218", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 107631, content_id: 2523ac3d-4c7e-40ea-a215-cbe5d3325218, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 107631, content_id: "2523ac3d-4c7e-40ea-a215-cbe5d3325218", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/dn7-5ta-mr-terry-tyas-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698248, content_id: 6021079c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:20 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 322628, content_id: fde07727-56e5-49b3-835e-9f289fc42761, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 322628, content_id: "fde07727-56e5-49b3-835e-9f289fc42761", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 107649, content_id: fde07727-56e5-49b3-835e-9f289fc42761, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 107649, content_id: "fde07727-56e5-49b3-835e-9f289fc42761", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/en11-0rf-tamar-renewable-power-hoddesdon-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698681, content_id: 6024ea2e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:39 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 380596, content_id: eef73ee3-a58b-4f20-b0a7-4aff9d3fc661, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 380596, content_id: "eef73ee3-a58b-4f20-b0a7-4aff9d3fc661", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 165738, content_id: eef73ee3-a58b-4f20-b0a7-4aff9d3fc661, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 165738, content_id: "eef73ee3-a58b-4f20-b0a7-4aff9d3fc661", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/environment-agency-application-made-to-impound-water, content_store: live
      # keeping id: 698386, content_id: 60225db9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:32 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 380792, content_id: 7aeb7191-8dfd-4d88-95b4-625682efdbf7, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 380792, content_id: "7aeb7191-8dfd-4d88-95b4-625682efdbf7", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 165934, content_id: 7aeb7191-8dfd-4d88-95b4-625682efdbf7, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 165934, content_id: "7aeb7191-8dfd-4d88-95b4-625682efdbf7", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ex36-3lt-mr-peter-delbridge-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698540, content_id: 60247602-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:18 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 269820, content_id: ce84453d-6f39-47ae-a1b9-6c51ee07ce91, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 269820, content_id: "ce84453d-6f39-47ae-a1b9-6c51ee07ce91", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 54646, content_id: ce84453d-6f39-47ae-a1b9-6c51ee07ce91, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 54646, content_id: "ce84453d-6f39-47ae-a1b9-6c51ee07ce91", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ex38-7ay-torrington-farmers-hunt-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698426, content_id: 6022e6d9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:59 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 381244, content_id: c0a34664-b2f1-44eb-a636-fd6f3a02a989, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 381244, content_id: "c0a34664-b2f1-44eb-a636-fd6f3a02a989", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 166385, content_id: c0a34664-b2f1-44eb-a636-fd6f3a02a989, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 166385, content_id: "c0a34664-b2f1-44eb-a636-fd6f3a02a989", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/fyfield-estates-limited-application-made-to-abstract-take-water, content_store: live
      # keeping id: 698538, content_id: 60246db9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:16 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 325255, content_id: a3d88b30-41bf-4e55-812a-8ff4ba5d308b, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 325255, content_id: "a3d88b30-41bf-4e55-812a-8ff4ba5d308b", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 110277, content_id: a3d88b30-41bf-4e55-812a-8ff4ba5d308b, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 110277, content_id: "a3d88b30-41bf-4e55-812a-8ff4ba5d308b", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/gu24-8hu-fairoaks-operations-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698206, content_id: 6020a861-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:58 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 383499, content_id: 8988b820-fa63-449b-9bdd-da65dadbc8f2, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 383499, content_id: "8988b820-fa63-449b-9bdd-da65dadbc8f2", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 168638, content_id: 8988b820-fa63-449b-9bdd-da65dadbc8f2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 168638, content_id: "8988b820-fa63-449b-9bdd-da65dadbc8f2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/gu34-3ej-mr-william-kerridge-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698311, content_id: 60219c1a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:52 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 271389, content_id: e00d536b-be6b-4122-ac4e-93288541c64e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 271389, content_id: "e00d536b-be6b-4122-ac4e-93288541c64e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 56211, content_id: e00d536b-be6b-4122-ac4e-93288541c64e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 56211, content_id: "e00d536b-be6b-4122-ac4e-93288541c64e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/health-professions-council-annual-report-2006-to-2007, content_store: live
      # keeping id: 686716, content_id: 5e9e297a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:17:44 UTC, publishing_app: whitehall, document_type: independent_report
      # deleting id: 326260, content_id: 932dbd8c-12c5-46a6-8ca2-bc42113ae291, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 326260, content_id: "932dbd8c-12c5-46a6-8ca2-bc42113ae291", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 111276, content_id: 932dbd8c-12c5-46a6-8ca2-bc42113ae291, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 111276, content_id: "932dbd8c-12c5-46a6-8ca2-bc42113ae291", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/health-professions-council-annual-report-and-accounts-2007-08, content_store: live
      # keeping id: 686097, content_id: 5e64b8cb-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:03:29 UTC, publishing_app: whitehall, document_type: independent_report
      # deleting id: 383834, content_id: 945dd603-4550-4b39-b92d-cb6f2d04be55, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 383834, content_id: "945dd603-4550-4b39-b92d-cb6f2d04be55", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 168981, content_id: 945dd603-4550-4b39-b92d-cb6f2d04be55, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 168981, content_id: "945dd603-4550-4b39-b92d-cb6f2d04be55", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/health-professions-council-annual-report-and-accounts-2009-to-2010, content_store: live
      # keeping id: 686600, content_id: 5e99f174-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:14:34 UTC, publishing_app: whitehall, document_type: independent_report
      # deleting id: 383836, content_id: d24e2a99-0d27-4d2f-8e29-222da4432fe6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 383836, content_id: "d24e2a99-0d27-4d2f-8e29-222da4432fe6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 168983, content_id: d24e2a99-0d27-4d2f-8e29-222da4432fe6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 168983, content_id: "d24e2a99-0d27-4d2f-8e29-222da4432fe6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/hospital-estates-and-facilities-statistics-201011, content_store: live
      # keeping id: 684204, content_id: 5dc4ac4a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 14:24:32 UTC, publishing_app: whitehall, document_type: transparency
      # deleting id: 384507, content_id: f8c6ae54-6d0e-4355-b027-8c0332e2f200, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 384507, content_id: "f8c6ae54-6d0e-4355-b027-8c0332e2f200", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 169656, content_id: f8c6ae54-6d0e-4355-b027-8c0332e2f200, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 169656, content_id: "f8c6ae54-6d0e-4355-b027-8c0332e2f200", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/hr3-6nt-p-t-baker-farms-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698130, content_id: 601fd8e3-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:19 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 326946, content_id: fb70aad7-8389-4f3f-99f8-51594f43fef4, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 326946, content_id: "fb70aad7-8389-4f3f-99f8-51594f43fef4", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 111967, content_id: fb70aad7-8389-4f3f-99f8-51594f43fef4, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 111967, content_id: "fb70aad7-8389-4f3f-99f8-51594f43fef4", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/initial-teacher-training-performance-profiles-2013-for-the-academic-year-2011-to-2012, content_store: live
      # keeping id: 876298, content_id: 5e5b328b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-07-28 11:16:19 UTC, publishing_app: whitehall, document_type: transparency
      # deleting id: 57671, content_id: 503ef1e5-3023-4ba5-a0cc-0fae65ccb15f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 57671, content_id: "503ef1e5-3023-4ba5-a0cc-0fae65ccb15f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/initial-teacher-training-performance-profiles-2013-management-data, content_store: live
      # keeping id: 876304, content_id: 5ebd0ce4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-07-28 11:18:16 UTC, publishing_app: whitehall, document_type: transparency
      # deleting id: 112844, content_id: 821dbcff-2c04-42b1-8cea-a50f74007d86, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 112844, content_id: "821dbcff-2c04-42b1-8cea-a50f74007d86", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ip13-6rz-mr-dennis-crowe-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698749, content_id: 6025883b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:18 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 273050, content_id: f2f0604c-bfe4-44e8-aeb2-b0d95fd39708, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 273050, content_id: "f2f0604c-bfe4-44e8-aeb2-b0d95fd39708", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 57890, content_id: f2f0604c-bfe4-44e8-aeb2-b0d95fd39708, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 57890, content_id: "f2f0604c-bfe4-44e8-aeb2-b0d95fd39708", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ip14-3na-valley-farm-poultry-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698902, content_id: 60274776-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:01:50 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 385952, content_id: 2e72c093-7bb1-41aa-b9a1-3a67918dfe19, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 385952, content_id: "2e72c093-7bb1-41aa-b9a1-3a67918dfe19", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 171108, content_id: 2e72c093-7bb1-41aa-b9a1-3a67918dfe19, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 171108, content_id: "2e72c093-7bb1-41aa-b9a1-3a67918dfe19", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ip19-0pl-northumbrian-water-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698315, content_id: 6021bb3b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:56 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 328111, content_id: 33e481e5-02fe-4927-8887-5ee31c63f444, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 328111, content_id: "33e481e5-02fe-4927-8887-5ee31c63f444", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 113126, content_id: 33e481e5-02fe-4927-8887-5ee31c63f444, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 113126, content_id: "33e481e5-02fe-4927-8887-5ee31c63f444", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ip2-8nb-brett-aggregates-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698424, content_id: 6022cc4f-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:55 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 385954, content_id: af724698-ea85-4de2-9ce5-a339b1c49a86, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 385954, content_id: "af724698-ea85-4de2-9ce5-a339b1c49a86", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 171110, content_id: af724698-ea85-4de2-9ce5-a339b1c49a86, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 171110, content_id: "af724698-ea85-4de2-9ce5-a339b1c49a86", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/itt-performance-profiles-management-information-2012-to-2013, content_store: live
      # keeping id: 876504, content_id: 60256551-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-07-28 12:26:13 UTC, publishing_app: whitehall, document_type: transparency
      # deleting id: 113230, content_id: b7eebbf4-e916-46ee-812a-789a23650340, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 113230, content_id: "b7eebbf4-e916-46ee-812a-789a23650340", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/kingston-small-boats-head-race-river-restriction-notice, content_store: live
      # keeping id: 698275, content_id: 60213d7b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:30 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 386277, content_id: fad5fc16-209e-42bb-a00e-13316e8074c4, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 386277, content_id: "fad5fc16-209e-42bb-a00e-13316e8074c4", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 171432, content_id: fad5fc16-209e-42bb-a00e-13316e8074c4, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 171432, content_id: "fad5fc16-209e-42bb-a00e-13316e8074c4", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/l35-3ss-mr-robin-seddon-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698273, content_id: 60213bb0-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:29 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 273312, content_id: 49c2366f-cecf-4363-9239-d47eb2374589, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 273312, content_id: "49c2366f-cecf-4363-9239-d47eb2374589", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 58154, content_id: 49c2366f-cecf-4363-9239-d47eb2374589, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 58154, content_id: "49c2366f-cecf-4363-9239-d47eb2374589", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/la6-2et-rigmaden-court-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698127, content_id: 601fc750-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:14 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 386333, content_id: c14a31a8-d1e4-4967-8b45-9e7a19929c10, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 386333, content_id: "c14a31a8-d1e4-4967-8b45-9e7a19929c10", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 171486, content_id: c14a31a8-d1e4-4967-8b45-9e7a19929c10, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 171486, content_id: "c14a31a8-d1e4-4967-8b45-9e7a19929c10", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/land-registry-welsh-language-scheme/cynllun-iaith-gymraeg-y-gofrestrfa-tir, content_store: draft
      # keeping id: 764557, content_id: 76b33939-02cf-41c2-89fa-bbffb3da16fa, state: draft, updated_at: 2016-05-26 15:17:04 UTC, publishing_app: whitehall, document_type: redirect
      # deleting id: 634180, content_id: 44aa01df-38dc-4690-b113-711392526e30, state: draft, updated_at: 2016-04-21 14:51:57 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: yes
      { id: 634180, content_id: "44aa01df-38dc-4690-b113-711392526e30", updated_at: "2016-04-21 14:51:57 UTC" },

      # base_path: /government/publications/le12-5tq-egdon-resource-u-k-limited-environmental-permit-applications-advertisement, content_store: live
      # keeping id: 698287, content_id: 60214cf7-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:35 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 386455, content_id: ceba926a-2825-471d-8ddb-3a231045b665, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 386455, content_id: "ceba926a-2825-471d-8ddb-3a231045b665", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 171611, content_id: ceba926a-2825-471d-8ddb-3a231045b665, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 171611, content_id: "ceba926a-2825-471d-8ddb-3a231045b665", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/le65-2un-mr-hayo-harmens-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698212, content_id: 6020b1e5-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:01 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 273416, content_id: 386e2495-6d55-4735-bc1b-6e13097f0596, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 273416, content_id: "386e2495-6d55-4735-bc1b-6e13097f0596", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 58260, content_id: 386e2495-6d55-4735-bc1b-6e13097f0596, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 58260, content_id: "386e2495-6d55-4735-bc1b-6e13097f0596", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/lead-local-flood-authorities-england-funding-for-2014-to-2015, content_store: live
      # keeping id: 690229, content_id: 5f185d58-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:48:38 UTC, publishing_app: whitehall, document_type: policy_paper
      # deleting id: 328667, content_id: 9a305458-cc38-430d-83e2-437f6834ad29, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 328667, content_id: "9a305458-cc38-430d-83e2-437f6834ad29", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 113676, content_id: 9a305458-cc38-430d-83e2-437f6834ad29, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 113676, content_id: "9a305458-cc38-430d-83e2-437f6834ad29", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ln11-8pg-elsham-linc-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698289, content_id: 60214e75-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:35 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 328958, content_id: 43a4921b-9770-4a2c-9023-fd10e7d17394, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 328958, content_id: "43a4921b-9770-4a2c-9023-fd10e7d17394", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 113975, content_id: 43a4921b-9770-4a2c-9023-fd10e7d17394, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 113975, content_id: "43a4921b-9770-4a2c-9023-fd10e7d17394", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ln4-8sf-st-andrews-church-parochial-church-council-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698334, content_id: 6021cd78-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:02 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 386816, content_id: 2c1e09f1-d00e-453a-a1ed-fe1d08953296, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 386816, content_id: "2c1e09f1-d00e-453a-a1ed-fe1d08953296", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 171978, content_id: 2c1e09f1-d00e-453a-a1ed-fe1d08953296, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 171978, content_id: "2c1e09f1-d00e-453a-a1ed-fe1d08953296", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/low-wood-hotel-1958-limited-and-holbeck-ghyll-country-house-hotel-limited-application-made-to-abstract-water-and-impound-water, content_store: live
      # keeping id: 698147, content_id: 60201739-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:29 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 387049, content_id: 5c0eea86-a633-48f7-86d5-29104f024d7f, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 387049, content_id: "5c0eea86-a633-48f7-86d5-29104f024d7f", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 172211, content_id: 5c0eea86-a633-48f7-86d5-29104f024d7f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 172211, content_id: "5c0eea86-a633-48f7-86d5-29104f024d7f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/m31-4ax-duro-felguera-uk-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698126, content_id: 601fc14f-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:13 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 387096, content_id: eb42e645-13d1-4650-b545-75c23f82cbef, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 387096, content_id: "eb42e645-13d1-4650-b545-75c23f82cbef", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 172256, content_id: eb42e645-13d1-4650-b545-75c23f82cbef, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 172256, content_id: "eb42e645-13d1-4650-b545-75c23f82cbef", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/markets-orders-and-undertakings-register, content_store: live
      # keeping id: 691348, content_id: 5f490b6c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:01:04 UTC, publishing_app: whitehall, document_type: corporate_report
      # deleting id: 329497, content_id: 5d3bf480-60da-490a-8f58-9d8a34c6d2c6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 329497, content_id: "5d3bf480-60da-490a-8f58-9d8a34c6d2c6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 114509, content_id: 5d3bf480-60da-490a-8f58-9d8a34c6d2c6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 114509, content_id: "5d3bf480-60da-490a-8f58-9d8a34c6d2c6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/me6-5ax-smurfit-kappa-uk-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698716, content_id: 60253f6b-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:59 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 387340, content_id: d9b265f8-daf1-4687-919b-ea1b760c9762, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 387340, content_id: "d9b265f8-daf1-4687-919b-ea1b760c9762", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 172503, content_id: d9b265f8-daf1-4687-919b-ea1b760c9762, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 172503, content_id: "d9b265f8-daf1-4687-919b-ea1b760c9762", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/min-423-revalidating-a-certificate-of-competency, content_store: live
      # keeping id: 690082, content_id: 5f153d98-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:47:10 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 274336, content_id: abad8da4-c4cc-4c92-97c7-cf181c38333c, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 274336, content_id: "abad8da4-c4cc-4c92-97c7-cf181c38333c", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 59186, content_id: abad8da4-c4cc-4c92-97c7-cf181c38333c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 59186, content_id: "abad8da4-c4cc-4c92-97c7-cf181c38333c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/min-480-new-requirements-for-security-training-for-shipboard-personnel, content_store: live
      # keeping id: 698470, content_id: 602355f6-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:22 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 274352, content_id: 91972667-11d8-4960-89be-1e2ec04eeff0, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 274352, content_id: "91972667-11d8-4960-89be-1e2ec04eeff0", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 59202, content_id: 91972667-11d8-4960-89be-1e2ec04eeff0, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 59202, content_id: "91972667-11d8-4960-89be-1e2ec04eeff0", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ne10-0el-northumbrian-water-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698722, content_id: 602545a0-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:01 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 330756, content_id: 04cd2952-b451-4444-b7ec-d81ec46cb3d7, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 330756, content_id: "04cd2952-b451-4444-b7ec-d81ec46cb3d7", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 115771, content_id: 04cd2952-b451-4444-b7ec-d81ec46cb3d7, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 115771, content_id: "04cd2952-b451-4444-b7ec-d81ec46cb3d7", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ne8-2pw-northumbrian-water-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698731, content_id: 60256c29-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:12 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 330778, content_id: c1caa87b-4e11-41eb-8121-e28f649defb1, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 330778, content_id: "c1caa87b-4e11-41eb-8121-e28f649defb1", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 115793, content_id: c1caa87b-4e11-41eb-8121-e28f649defb1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 115793, content_id: "c1caa87b-4e11-41eb-8121-e28f649defb1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ng13-9hb-lc-and-jm-parker-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698131, content_id: 601fddc6-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:19 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 388737, content_id: 7b165dae-70e5-44fd-a028-93dcd6b94a5a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 388737, content_id: "7b165dae-70e5-44fd-a028-93dcd6b94a5a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 173898, content_id: 7b165dae-70e5-44fd-a028-93dcd6b94a5a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 173898, content_id: "7b165dae-70e5-44fd-a028-93dcd6b94a5a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ng13-9ne-sheardown-farms-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698965, content_id: 6027ddbb-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:28 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 275063, content_id: d734bf56-1445-4862-9e0a-db29089177b7, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 275063, content_id: "d734bf56-1445-4862-9e0a-db29089177b7", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 59927, content_id: d734bf56-1445-4862-9e0a-db29089177b7, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 59927, content_id: "d734bf56-1445-4862-9e0a-db29089177b7", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/nn17-3jw-anglian-water-services-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698448, content_id: 602312ec-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:09 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 275208, content_id: 117f4df3-4688-4092-9316-31fff3235714, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 275208, content_id: "117f4df3-4688-4092-9316-31fff3235714", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 60076, content_id: 117f4df3-4688-4092-9316-31fff3235714, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 60076, content_id: "117f4df3-4688-4092-9316-31fff3235714", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/nn3-6rx-greencore-food-to-go-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698680, content_id: 6024e780-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:38 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 388965, content_id: 31e86a0e-cfa2-440a-92a7-bf41fdc88413, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 388965, content_id: "31e86a0e-cfa2-440a-92a7-bf41fdc88413", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 174126, content_id: 31e86a0e-cfa2-440a-92a7-bf41fdc88413, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 174126, content_id: "31e86a0e-cfa2-440a-92a7-bf41fdc88413", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/nr28-9ry-dalkia-plc-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698720, content_id: 60254389-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:00 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 389249, content_id: 9f04055f-39bd-4cce-9baf-7c8f86cd42a9, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 389249, content_id: "9f04055f-39bd-4cce-9baf-7c8f86cd42a9", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 174404, content_id: 9f04055f-39bd-4cce-9baf-7c8f86cd42a9, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 174404, content_id: "9f04055f-39bd-4cce-9baf-7c8f86cd42a9", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/nr28-9ry-h-j-heinz-frozen-and-chilled-foods-europe-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698781, content_id: 6025ee3f-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:38 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 331451, content_id: 8a9b0494-d959-4f92-a97f-209a47db3141, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 331451, content_id: "8a9b0494-d959-4f92-a97f-209a47db3141", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 116468, content_id: 8a9b0494-d959-4f92-a97f-209a47db3141, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 116468, content_id: "8a9b0494-d959-4f92-a97f-209a47db3141", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/nr30-3qd-veolia-es-uk-limited-environmental-permit-application-advertisement--2, content_store: live
      # keeping id: 698353, content_id: 602200da-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:11 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 275446, content_id: 80bc3327-b39e-4655-aa33-0b232828b75a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 275446, content_id: "80bc3327-b39e-4655-aa33-0b232828b75a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 60311, content_id: 80bc3327-b39e-4655-aa33-0b232828b75a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 60311, content_id: "80bc3327-b39e-4655-aa33-0b232828b75a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/official-searches-of-the-index-map/1496506, content_store: draft
      # keeping id: 793313, content_id: 4029527f-5269-4ad8-94f9-09f014bcfd83, state: draft, updated_at: 2016-06-01 11:10:18 UTC, publishing_app: whitehall, document_type: redirect
      # deleting id: 731734, content_id: 3a0e34dc-2de7-4e65-b195-850e36163a9c, state: draft, updated_at: 2016-05-19 11:35:21 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: yes
      { id: 731734, content_id: "3a0e34dc-2de7-4e65-b195-850e36163a9c", updated_at: "2016-05-19 11:35:21 UTC" },

      # base_path: /government/publications/paye-internet-submissions-expenses-and-benefits-schema-2015-to-2016, content_store: draft
      # keeping id: 390242, content_id: 6026b096-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 17:01:15 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 414734, content_id: d9b51c66-4fff-488a-8bc4-9d0a5f07d1d9, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 414734, content_id: "d9b51c66-4fff-488a-8bc4-9d0a5f07d1d9", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/pe28-5nt-mr-stephen-wright-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698793, content_id: 60261329-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:44 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 276248, content_id: b9bd2b67-3e47-4b17-83f2-8480b6f336a6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 276248, content_id: "b9bd2b67-3e47-4b17-83f2-8480b6f336a6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 61110, content_id: b9bd2b67-3e47-4b17-83f2-8480b6f336a6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 61110, content_id: "b9bd2b67-3e47-4b17-83f2-8480b6f336a6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/pe31-6xj-mr-hugh-kemsley-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698154, content_id: 602020ae-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:33 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 332464, content_id: 89d83085-0688-4d19-ae78-0ad4f81e5628, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 332464, content_id: "89d83085-0688-4d19-ae78-0ad4f81e5628", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 117511, content_id: 89d83085-0688-4d19-ae78-0ad4f81e5628, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 117511, content_id: "89d83085-0688-4d19-ae78-0ad4f81e5628", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/pe6-7th-biffa-waste-services-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698167, content_id: 6020511c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:41 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 390312, content_id: 17a39f6a-bb0a-4213-adb2-06db826c6915, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 390312, content_id: "17a39f6a-bb0a-4213-adb2-06db826c6915", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 175472, content_id: 17a39f6a-bb0a-4213-adb2-06db826c6915, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 175472, content_id: "17a39f6a-bb0a-4213-adb2-06db826c6915", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/pe7-2hd-east-anglian-resources-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698356, content_id: 6022062a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:13 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 390313, content_id: a4f2b121-1f70-4889-938a-027f49ab9065, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 390313, content_id: "a4f2b121-1f70-4889-938a-027f49ab9065", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 175473, content_id: a4f2b121-1f70-4889-938a-027f49ab9065, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 175473, content_id: "a4f2b121-1f70-4889-938a-027f49ab9065", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/pl18-9sq-mr-nicholas-cole-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698351, content_id: 6021f340-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:10 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 332738, content_id: b2564ad1-b74c-4659-a7cf-5f63f3f1e4f1, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 332738, content_id: "b2564ad1-b74c-4659-a7cf-5f63f3f1e4f1", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 117786, content_id: b2564ad1-b74c-4659-a7cf-5f63f3f1e4f1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 117786, content_id: "b2564ad1-b74c-4659-a7cf-5f63f3f1e4f1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/po18-8st-mr-lawrence-marsh-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698477, content_id: 602376b3-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:26 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 390720, content_id: ef8570cc-46a4-4be2-8f69-b1aa2571826e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 390720, content_id: "ef8570cc-46a4-4be2-8f69-b1aa2571826e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 175882, content_id: ef8570cc-46a4-4be2-8f69-b1aa2571826e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 175882, content_id: "ef8570cc-46a4-4be2-8f69-b1aa2571826e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/psn-local-public-services-data-handling-guidelines, content_store: live
      # keeping id: 699174, content_id: 602b723a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:04:56 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 333493, content_id: d55dea3f-1e4a-4d5f-b34d-83d15f76c227, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 333493, content_id: "d55dea3f-1e4a-4d5f-b34d-83d15f76c227", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 118544, content_id: d55dea3f-1e4a-4d5f-b34d-83d15f76c227, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 118544, content_id: "d55dea3f-1e4a-4d5f-b34d-83d15f76c227", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/rg17-0ur-mr-john-smith-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698360, content_id: 60220bd4-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:15 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 278088, content_id: 7374536e-bdae-46f6-8fab-bed071ffeddd, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 278088, content_id: "7374536e-bdae-46f6-8fab-bed071ffeddd", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 62963, content_id: 7374536e-bdae-46f6-8fab-bed071ffeddd, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 62963, content_id: "7374536e-bdae-46f6-8fab-bed071ffeddd", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/rg1-8na-balfour-beatty-plc-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698376, content_id: 60224c43-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:27 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 278085, content_id: b83ccd39-571c-495d-90c2-2407d371b57f, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 278085, content_id: "b83ccd39-571c-495d-90c2-2407d371b57f", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 62960, content_id: b83ccd39-571c-495d-90c2-2407d371b57f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 62960, content_id: "b83ccd39-571c-495d-90c2-2407d371b57f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/rg26-5sb-mr-michael-and-mrs-amanda-baker-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698398, content_id: 60227f99-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:40 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 278091, content_id: 1c6cfbc0-70e0-4158-b551-abb0ab131cc5, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 278091, content_id: "1c6cfbc0-70e0-4158-b551-abb0ab131cc5", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 62966, content_id: 1c6cfbc0-70e0-4158-b551-abb0ab131cc5, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 62966, content_id: "1c6cfbc0-70e0-4158-b551-abb0ab131cc5", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/rg29-1jp-mrs-marion-holloway-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698471, content_id: 602355a6-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:22 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 393112, content_id: 10bc90ee-5e51-46af-9761-10e1ad18103c, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 393112, content_id: "10bc90ee-5e51-46af-9761-10e1ad18103c", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 178282, content_id: 10bc90ee-5e51-46af-9761-10e1ad18103c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 178282, content_id: "10bc90ee-5e51-46af-9761-10e1ad18103c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/rh7-6hu-matthews-sussex-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698967, content_id: 6027e1e9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:02:29 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 278097, content_id: 9ba693f4-f24f-455d-8052-649d731a7113, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 278097, content_id: "9ba693f4-f24f-455d-8052-649d731a7113", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 62972, content_id: 9ba693f4-f24f-455d-8052-649d731a7113, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 62972, content_id: "9ba693f4-f24f-455d-8052-649d731a7113", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/rhino-horn-worked-items-application-for-pre-sale-approval, content_store: live
      # keeping id: 694753, content_id: 5f65c441-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:24:50 UTC, publishing_app: whitehall, document_type: form
      # deleting id: 278100, content_id: a47ba83c-c779-4956-aa94-a022bdcd1e3c, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 278100, content_id: "a47ba83c-c779-4956-aa94-a022bdcd1e3c", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 62975, content_id: a47ba83c-c779-4956-aa94-a022bdcd1e3c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 62975, content_id: "a47ba83c-c779-4956-aa94-a022bdcd1e3c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/s33-6rp-hope-construction-materials-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698286, content_id: 60214923-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:34 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 393357, content_id: 7daaa5d4-2f09-4510-bd89-19f2cbedeeb5, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 393357, content_id: "7daaa5d4-2f09-4510-bd89-19f2cbedeeb5", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 178523, content_id: 7daaa5d4-2f09-4510-bd89-19f2cbedeeb5, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 178523, content_id: "7daaa5d4-2f09-4510-bd89-19f2cbedeeb5", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/s44-5qj-national-trust-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698307, content_id: 60219570-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:51 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 335206, content_id: f7b6dc59-be18-4209-bcc3-0e0005226007, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 335206, content_id: "f7b6dc59-be18-4209-bcc3-0e0005226007", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 120256, content_id: f7b6dc59-be18-4209-bcc3-0e0005226007, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 120256, content_id: "f7b6dc59-be18-4209-bcc3-0e0005226007", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/sale-of-miscellaneous-surplus-defence-equipment-in-cyprus, content_store: live
      # keeping id: 696936, content_id: 5fea04a5-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:44:52 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 278337, content_id: 4f5b0a2f-e93e-4f93-b87f-960492d5f6f4, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 278337, content_id: "4f5b0a2f-e93e-4f93-b87f-960492d5f6f4", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 63214, content_id: 4f5b0a2f-e93e-4f93-b87f-960492d5f6f4, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 63214, content_id: "4f5b0a2f-e93e-4f93-b87f-960492d5f6f4", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/se10-0nu-energy-10-greenwich-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698494, content_id: 6023a383-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:38 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 278475, content_id: 7566757f-614f-4222-9e5d-aa9c273460bd, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 278475, content_id: "7566757f-614f-4222-9e5d-aa9c273460bd", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 63351, content_id: 7566757f-614f-4222-9e5d-aa9c273460bd, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 63351, content_id: "7566757f-614f-4222-9e5d-aa9c273460bd", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/seaton-weir-flood-defence-repair-works, content_store: live
      # keeping id: 697931, content_id: 601c1e09-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:53:15 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 393680, content_id: 48755bb8-2968-4ad7-8aeb-de19b64e3db9, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 393680, content_id: "48755bb8-2968-4ad7-8aeb-de19b64e3db9", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 178845, content_id: 48755bb8-2968-4ad7-8aeb-de19b64e3db9, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 178845, content_id: "48755bb8-2968-4ad7-8aeb-de19b64e3db9", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/sn14-7ex-mrs-joanna-sarah-reed-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698352, content_id: 6021f7c4-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:10 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 394293, content_id: 58626990-cfd5-4d41-a491-bc790e6bb2cc, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 394293, content_id: "58626990-cfd5-4d41-a491-bc790e6bb2cc", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 179462, content_id: 58626990-cfd5-4d41-a491-bc790e6bb2cc, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 179462, content_id: "58626990-cfd5-4d41-a491-bc790e6bb2cc", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/so21-1ta-mr-clive-pace-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698209, content_id: 6020b0b4-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:01 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 336078, content_id: a7b6e2fa-8a66-463c-a600-6a40297d4295, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 336078, content_id: "a7b6e2fa-8a66-463c-a600-6a40297d4295", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 121136, content_id: a7b6e2fa-8a66-463c-a600-6a40297d4295, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 121136, content_id: "a7b6e2fa-8a66-463c-a600-6a40297d4295", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/so30-2hb-wessex-demolition-and-salvage-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698282, content_id: 602144ac-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:32 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 336082, content_id: dbfc6108-0c4a-43af-9e96-12a6d3c95155, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 336082, content_id: "dbfc6108-0c4a-43af-9e96-12a6d3c95155", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 121140, content_id: dbfc6108-0c4a-43af-9e96-12a6d3c95155, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 121140, content_id: "dbfc6108-0c4a-43af-9e96-12a6d3c95155", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/so41-8af-meryl-armitage-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698347, content_id: 6021e93e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:09 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 336085, content_id: a3862275-f1bf-477f-8757-12b79097175a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 336085, content_id: "a3862275-f1bf-477f-8757-12b79097175a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 121143, content_id: a3862275-f1bf-477f-8757-12b79097175a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 121143, content_id: "a3862275-f1bf-477f-8757-12b79097175a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/southerham-grey-pit-flood-defence-repair-works, content_store: live
      # keeping id: 697878, content_id: 601b8f2e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:52:48 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 336237, content_id: dcaf9f5c-2e24-4796-abdf-eb39230c1a27, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 336237, content_id: "dcaf9f5c-2e24-4796-abdf-eb39230c1a27", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 121297, content_id: dcaf9f5c-2e24-4796-abdf-eb39230c1a27, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 121297, content_id: "dcaf9f5c-2e24-4796-abdf-eb39230c1a27", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/sp5-5jw-mr-john-parnell-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698438, content_id: 602304ee-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:06 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 279012, content_id: 57ac08ed-bf7a-44c3-ab3f-fb89f661ce3e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 279012, content_id: "57ac08ed-bf7a-44c3-ab3f-fb89f661ce3e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 63896, content_id: 57ac08ed-bf7a-44c3-ab3f-fb89f661ce3e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 63896, content_id: "57ac08ed-bf7a-44c3-ab3f-fb89f661ce3e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/sp6-2pz-mrs-margaret-bunyard-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698914, content_id: 60275cee-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:01:54 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 279013, content_id: ace8140b-f343-483a-9f08-f05152774393, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 279013, content_id: "ace8140b-f343-483a-9f08-f05152774393", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 63897, content_id: ace8140b-f343-483a-9f08-f05152774393, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 63897, content_id: "ace8140b-f343-483a-9f08-f05152774393", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/st10-3eq-lafarge-tarmac-cement-and-lime-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698501, content_id: 6023bed6-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:41 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 336519, content_id: 5679114b-562e-4c0b-859a-e2fa7c97fe62, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 336519, content_id: "5679114b-562e-4c0b-859a-e2fa7c97fe62", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 121577, content_id: 5679114b-562e-4c0b-859a-e2fa7c97fe62, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 121577, content_id: "5679114b-562e-4c0b-859a-e2fa7c97fe62", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/sy7-0qb-mrs-caroline-mann-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698134, content_id: 601fe37c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:20 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 395335, content_id: 8c9cbafe-401b-4569-abfb-a22b6a9150cb, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 395335, content_id: "8c9cbafe-401b-4569-abfb-a22b6a9150cb", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 180506, content_id: 8c9cbafe-401b-4569-abfb-a22b6a9150cb, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 180506, content_id: "8c9cbafe-401b-4569-abfb-a22b6a9150cb", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ta5-2bq-s-roberts-and-son-bridgwater-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698350, content_id: 6021f259-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:10 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 395395, content_id: b1a009e4-0fab-417d-99df-7ca8061d17d4, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 395395, content_id: "b1a009e4-0fab-417d-99df-7ca8061d17d4", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 180566, content_id: b1a009e4-0fab-417d-99df-7ca8061d17d4, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 180566, content_id: "b1a009e4-0fab-417d-99df-7ca8061d17d4", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ta9-3pz-secret-world-wildlife-rescue-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698136, content_id: 601ff0e9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:22 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 395399, content_id: 79e9b44e-6ed5-4c05-8dd1-2270b6f0c3d2, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 395399, content_id: "79e9b44e-6ed5-4c05-8dd1-2270b6f0c3d2", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 180570, content_id: 79e9b44e-6ed5-4c05-8dd1-2270b6f0c3d2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 180570, content_id: "79e9b44e-6ed5-4c05-8dd1-2270b6f0c3d2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tackling-irresponsible-dog-ownership-draft-practitioners-manual, content_store: live
      # keeping id: 686552, content_id: 5e972bd5-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:12:58 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 279711, content_id: 2a63ded1-26db-4c6c-83a9-7a83055674ac, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 279711, content_id: "2a63ded1-26db-4c6c-83a9-7a83055674ac", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 64596, content_id: 2a63ded1-26db-4c6c-83a9-7a83055674ac, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 64596, content_id: "2a63ded1-26db-4c6c-83a9-7a83055674ac", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tf13-6qn-benbow-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698432, content_id: 6022fe1c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:04 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 280032, content_id: f416403e-3d6f-409e-a512-1189c200af02, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 280032, content_id: "f416403e-3d6f-409e-a512-1189c200af02", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 64920, content_id: f416403e-3d6f-409e-a512-1189c200af02, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 64920, content_id: "f416403e-3d6f-409e-a512-1189c200af02", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tn20-6jj-mrs-jennifer-dunlop-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698468, content_id: 602354aa-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:22 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 396903, content_id: 5d4c1ab4-f800-4e58-ac55-2601f756e0ba, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 396903, content_id: "5d4c1ab4-f800-4e58-ac55-2601f756e0ba", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 182080, content_id: 5d4c1ab4-f800-4e58-ac55-2601f756e0ba, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 182080, content_id: "5d4c1ab4-f800-4e58-ac55-2601f756e0ba", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tn23-3hf-mr-russell-marsh-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698208, content_id: 6020abba-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:59 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 338808, content_id: eba35d3a-a28c-4f8d-ba3e-2fa7dd8135b3, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 338808, content_id: "eba35d3a-a28c-4f8d-ba3e-2fa7dd8135b3", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 123869, content_id: eba35d3a-a28c-4f8d-ba3e-2fa7dd8135b3, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 123869, content_id: "eba35d3a-a28c-4f8d-ba3e-2fa7dd8135b3", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tn25-6nh-mrs-rochelle-godden-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698396, content_id: 602275d3-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:57:39 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 396907, content_id: 10c703d6-796a-4e3a-91e6-0611e601e710, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 396907, content_id: "10c703d6-796a-4e3a-91e6-0611e601e710", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 182084, content_id: 10c703d6-796a-4e3a-91e6-0611e601e710, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 182084, content_id: "10c703d6-796a-4e3a-91e6-0611e601e710", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tn27-9eu-mrs-kathy-hook-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698466, content_id: 6023537a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:21 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 338812, content_id: 3dd9f331-d44e-4d8b-8243-fa2ec0e7d7a1, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 338812, content_id: "3dd9f331-d44e-4d8b-8243-fa2ec0e7d7a1", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 123873, content_id: 3dd9f331-d44e-4d8b-8243-fa2ec0e7d7a1, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 123873, content_id: "3dd9f331-d44e-4d8b-8243-fa2ec0e7d7a1", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tn31-6eu-mr-carl-mumford-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698469, content_id: 6023545e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:22 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 280667, content_id: 8319ee15-4153-44c3-bf07-4147ad41813f, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 280667, content_id: "8319ee15-4153-44c3-bf07-4147ad41813f", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 65555, content_id: 8319ee15-4153-44c3-bf07-4147ad41813f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 65555, content_id: "8319ee15-4153-44c3-bf07-4147ad41813f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tq12-6ut-kj-howard-civil-engineering-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698677, content_id: 6024e572-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:38 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 396997, content_id: d1a329c0-f529-477a-8457-407553da9ea2, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 396997, content_id: "d1a329c0-f529-477a-8457-407553da9ea2", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 182175, content_id: d1a329c0-f529-477a-8457-407553da9ea2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 182175, content_id: "d1a329c0-f529-477a-8457-407553da9ea2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/tr10-9ed-mr-david-trethewey-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698542, content_id: 60247ad4-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:59:19 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 280721, content_id: 34ce58c8-fe3b-4cd5-adde-76c9533b22a3, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 280721, content_id: "34ce58c8-fe3b-4cd5-adde-76c9533b22a3", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 65609, content_id: 34ce58c8-fe3b-4cd5-adde-76c9533b22a3, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 65609, content_id: "34ce58c8-fe3b-4cd5-adde-76c9533b22a3", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ts2-1sd-port-clarence-energy-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698909, content_id: 60274c99-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:01:52 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 397307, content_id: 48a1bb3b-cf91-4d25-a6c9-59d54510d31f, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 397307, content_id: "48a1bb3b-cf91-4d25-a6c9-59d54510d31f", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 182488, content_id: 48a1bb3b-cf91-4d25-a6c9-59d54510d31f, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 182488, content_id: "48a1bb3b-cf91-4d25-a6c9-59d54510d31f", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/ub3-4qr-fm-conway-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698492, content_id: 60239b5a-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:58:36 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 397411, content_id: 33e954ae-b142-4d18-b715-8409d659e86b, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 397411, content_id: "33e954ae-b142-4d18-b715-8409d659e86b", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 182595, content_id: 33e954ae-b142-4d18-b715-8409d659e86b, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 182595, content_id: "33e954ae-b142-4d18-b715-8409d659e86b", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/wa7-1pn-kier-infrastructure-and-overseas-limited-fcc-construccion-sa-and-samsung-ct-ecuk-limited-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698135, content_id: 601fe3c7-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:55:20 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 339993, content_id: 54d30419-3f84-4399-baf1-6121efd0315e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 339993, content_id: "54d30419-3f84-4399-baf1-6121efd0315e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 125066, content_id: 54d30419-3f84-4399-baf1-6121efd0315e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 125066, content_id: "54d30419-3f84-4399-baf1-6121efd0315e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-si-ntem-sub-models, content_store: live
      # keeping id: 685915, content_id: 5e5cabdd-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 14:59:28 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 340119, content_id: 343f6880-04d3-4172-b6ea-e9f936b81e18, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 340119, content_id: "343f6880-04d3-4172-b6ea-e9f936b81e18", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 125195, content_id: 343f6880-04d3-4172-b6ea-e9f936b81e18, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 125195, content_id: "343f6880-04d3-4172-b6ea-e9f936b81e18", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-data-book-may-2014, content_store: live
      # keeping id: 693687, content_id: 5f5cf7f0-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:17:52 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 398450, content_id: 98d4ac38-4285-4bdf-9d5c-3443e609ab7e, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 398450, content_id: "98d4ac38-4285-4bdf-9d5c-3443e609ab7e", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 183626, content_id: 98d4ac38-4285-4bdf-9d5c-3443e609ab7e, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 183626, content_id: "98d4ac38-4285-4bdf-9d5c-3443e609ab7e", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-unit-a1-1-cost-benefit-analysis, content_store: live
      # keeping id: 686664, content_id: 5e9c7f3c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:16:22 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 398453, content_id: e4ac008c-f8e9-4e9b-b494-27c99bde1bb2, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 398453, content_id: "e4ac008c-f8e9-4e9b-b494-27c99bde1bb2", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 183629, content_id: e4ac008c-f8e9-4e9b-b494-27c99bde1bb2, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 183629, content_id: "e4ac008c-f8e9-4e9b-b494-27c99bde1bb2", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-unit-a1-2-scheme-costs, content_store: live
      # keeping id: 686663, content_id: 5e9c7fc1-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:16:22 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 340120, content_id: 240f763f-d48a-4e00-b099-02cfeddc555c, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 340120, content_id: "240f763f-d48a-4e00-b099-02cfeddc555c", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 125196, content_id: 240f763f-d48a-4e00-b099-02cfeddc555c, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 125196, content_id: "240f763f-d48a-4e00-b099-02cfeddc555c", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-unit-a1-3-user-and-provider-impacts-may-2014, content_store: live
      # keeping id: 693682, content_id: 5f5cf389-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:17:50 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 340122, content_id: 9d745d47-aef2-462c-8eb7-c8d3a5d65010, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 340122, content_id: "9d745d47-aef2-462c-8eb7-c8d3a5d65010", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 125198, content_id: 9d745d47-aef2-462c-8eb7-c8d3a5d65010, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 125198, content_id: "9d745d47-aef2-462c-8eb7-c8d3a5d65010", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-unit-a3-environmental-impact-appraisal-may-2014, content_store: live
      # keeping id: 693684, content_id: 5f5cf4b9-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:17:51 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 281686, content_id: 58f5e461-e140-4234-923f-245daf386ed6, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 281686, content_id: "58f5e461-e140-4234-923f-245daf386ed6", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 66580, content_id: 58f5e461-e140-4234-923f-245daf386ed6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 66580, content_id: "58f5e461-e140-4234-923f-245daf386ed6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-unit-a4-1-social-impact-appraisal, content_store: live
      # keeping id: 686346, content_id: 5e906263-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:09:21 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 340124, content_id: 0e414e1e-e844-480e-abf9-4eff42e97536, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 340124, content_id: "0e414e1e-e844-480e-abf9-4eff42e97536", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 125200, content_id: 0e414e1e-e844-480e-abf9-4eff42e97536, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 125200, content_id: "0e414e1e-e844-480e-abf9-4eff42e97536", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-unit-a5-3-rail-appraisal, content_store: live
      # keeping id: 686549, content_id: 5e97268c-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 15:12:56 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 281687, content_id: 43820d3a-c408-439f-90b4-6faffd82d997, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 281687, content_id: "43820d3a-c408-439f-90b4-6faffd82d997", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 66581, content_id: 43820d3a-c408-439f-90b4-6faffd82d997, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 66581, content_id: "43820d3a-c408-439f-90b4-6faffd82d997", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/webtag-tag-unit-m4-forecasting-and-uncertainty-may-2014, content_store: live
      # keeping id: 693685, content_id: 5f5cf677-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:17:51 UTC, publishing_app: whitehall, document_type: guidance
      # deleting id: 340129, content_id: 94d48789-9096-4484-a0f9-9c4badedb48a, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 340129, content_id: "94d48789-9096-4484-a0f9-9c4badedb48a", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 125204, content_id: 94d48789-9096-4484-a0f9-9c4badedb48a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 125204, content_id: "94d48789-9096-4484-a0f9-9c4badedb48a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/wr6-5qq-mr-james-terry-brevitt-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698295, content_id: 6021752e-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 16:56:41 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 398819, content_id: 1a5139d6-f1ee-4dc7-8b9b-18887a304325, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 398819, content_id: "1a5139d6-f1ee-4dc7-8b9b-18887a304325", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 183998, content_id: 1a5139d6-f1ee-4dc7-8b9b-18887a304325, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 183998, content_id: "1a5139d6-f1ee-4dc7-8b9b-18887a304325", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/publications/yo8-8eq-mr-steven-masters-environmental-permit-application-advertisement, content_store: live
      # keeping id: 698808, content_id: 60263b00-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 17:00:51 UTC, publishing_app: whitehall, document_type: notice
      # deleting id: 398876, content_id: b857dbaf-2959-43be-8a73-2bc7c8ed4b6b, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 398876, content_id: "b857dbaf-2959-43be-8a73-2bc7c8ed4b6b", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 184055, content_id: b857dbaf-2959-43be-8a73-2bc7c8ed4b6b, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 184055, content_id: "b857dbaf-2959-43be-8a73-2bc7c8ed4b6b", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/statistics/hospital-estates-and-facilities-statistics-2009-10, content_store: live
      # keeping id: 684203, content_id: 5dc4aca2-7631-11e4-a3cb-005056011aef, state: unpublished, unpublishing_type: withdrawal, updated_at: 2016-05-13 14:24:32 UTC, publishing_app: whitehall, document_type: official_statistics
      # deleting id: 402699, content_id: 28ee067f-4c67-460e-ac17-c2ff46cb02ad, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 402699, content_id: "28ee067f-4c67-460e-ac17-c2ff46cb02ad", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 187888, content_id: 28ee067f-4c67-460e-ac17-c2ff46cb02ad, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: whitehall, document_type: placeholder, details match item to keep: no
      { id: 187888, content_id: "28ee067f-4c67-460e-ac17-c2ff46cb02ad", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /government/world-location-news/171142.es-419, content_store: live
      # keeping id: 404303, content_id: 5e34001e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:51:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685530, content_id: 5e34001e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:51:56 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685530, content_id: "5e34001e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:51:56 UTC" },

      # base_path: /government/world-location-news/171176.pl, content_store: live
      # keeping id: 285872, content_id: 5e341f7b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685532, content_id: 5e341f7b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685532, content_id: "5e341f7b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:00 UTC" },

      # base_path: /government/world-location-news/171317.el, content_store: live
      # keeping id: 685550, content_id: 5e346684-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404304, content_id: 5e346684-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404304, content_id: "5e346684-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:15 UTC" },

      # base_path: /government/world-location-news/171320.it, content_store: live
      # keeping id: 285873, content_id: 5e346763-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685549, content_id: 5e346763-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685549, content_id: "5e346763-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:15 UTC" },

      # base_path: /government/world-location-news/171411.de, content_store: live
      # keeping id: 685559, content_id: 5e348978-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345724, content_id: 5e348978-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345724, content_id: "5e348978-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:25 UTC" },

      # base_path: /government/world-location-news/171417.fr, content_store: live
      # keeping id: 345725, content_id: 5e348d86-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685558, content_id: 5e348d86-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685558, content_id: "5e348d86-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:26 UTC" },

      # base_path: /government/world-location-news/171493.fr, content_store: live
      # keeping id: 345726, content_id: 5e34bac7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685564, content_id: 5e34bac7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685564, content_id: "5e34bac7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:34 UTC" },

      # base_path: /government/world-location-news/171610.de, content_store: live
      # keeping id: 685598, content_id: 5e34f95c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 252558, content_id: 5e34f95c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 252558, content_id: "5e34f95c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:50 UTC" },

      # base_path: /government/world-location-news/171667.pt, content_store: live
      # keeping id: 345727, content_id: 5e350d59-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685604, content_id: 5e350d59-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:52:56 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685604, content_id: "5e350d59-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:52:56 UTC" },

      # base_path: /government/world-location-news/171845.es-419, content_store: live
      # keeping id: 404305, content_id: 5e3572c4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685613, content_id: 5e3572c4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685613, content_id: "5e3572c4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:17 UTC" },

      # base_path: /government/world-location-news/171848.it, content_store: draft
      # keeping id: 685617, content_id: 5e357929-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:53:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685616, content_id: 5e357929-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:53:18 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685616, content_id: "5e357929-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:18 UTC" },

      # base_path: /government/world-location-news/171848.it, content_store: live
      # keeping id: 285874, content_id: 5e357929-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685614, content_id: 5e357929-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685614, content_id: "5e357929-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:17 UTC" },

      # base_path: /government/world-location-news/171850.es-419, content_store: live
      # keeping id: 404306, content_id: 5e3579bf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685615, content_id: 5e3579bf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685615, content_id: "5e3579bf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:17 UTC" },

      # base_path: /government/world-location-news/171976.de, content_store: live
      # keeping id: 685625, content_id: 5e35a9ee-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 249112, content_id: 5e35a9ee-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 249112, content_id: "5e35a9ee-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:30 UTC" },

      # base_path: /government/world-location-news/172155.es, content_store: live
      # keeping id: 285875, content_id: 5e360c46-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685635, content_id: 5e360c46-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685635, content_id: "5e360c46-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:49 UTC" },

      # base_path: /government/world-location-news/172185.fr, content_store: draft
      # keeping id: 404307, content_id: 5e3617cf-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:53:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685637, content_id: 5e3617cf-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:53:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685637, content_id: "5e3617cf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:52 UTC" },

      # base_path: /government/world-location-news/172237.es-419, content_store: live
      # keeping id: 345728, content_id: 5e362a06-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:58 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685642, content_id: 5e362a06-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:53:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685642, content_id: "5e362a06-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:53:57 UTC" },

      # base_path: /government/world-location-news/172440.es, content_store: draft
      # keeping id: 685664, content_id: 5e36995e-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:54:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685663, content_id: 5e36995e-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:54:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685663, content_id: "5e36995e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:54:17 UTC" },

      # base_path: /government/world-location-news/172535.ja, content_store: live
      # keeping id: 285876, content_id: 5e36c0fa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:54:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685670, content_id: 5e36c0fa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:54:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685670, content_id: "5e36c0fa-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:54:28 UTC" },

      # base_path: /government/world-location-news/172625.it, content_store: live
      # keeping id: 404285, content_id: 5e36f10b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:54:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685675, content_id: 5e36f10b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:54:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685675, content_id: "5e36f10b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:54:37 UTC" },

      # base_path: /government/world-location-news/172683.fr, content_store: live
      # keeping id: 345729, content_id: 5e370ae3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:54:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685679, content_id: 5e370ae3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:54:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685679, content_id: "5e370ae3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:54:42 UTC" },

      # base_path: /government/world-location-news/172849.pt, content_store: live
      # keeping id: 404308, content_id: 5e3768b9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685690, content_id: 5e3768b9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:54:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685690, content_id: "5e3768b9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:54:59 UTC" },

      # base_path: /government/world-location-news/172968.pt, content_store: live
      # keeping id: 404309, content_id: 5e37994d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685694, content_id: 5e37994d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685694, content_id: "5e37994d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:55:12 UTC" },

      # base_path: /government/world-location-news/172981.ur, content_store: live
      # keeping id: 285878, content_id: 5e37ac1d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685697, content_id: 5e37ac1d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685697, content_id: "5e37ac1d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:55:13 UTC" },

      # base_path: /government/world-location-news/173029.lt, content_store: live
      # keeping id: 404310, content_id: 5e37bd02-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:19 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685702, content_id: 5e37bd02-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:18 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685702, content_id: "5e37bd02-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:55:18 UTC" },

      # base_path: /government/world-location-news/173244.lt, content_store: live
      # keeping id: 404311, content_id: 5e382118-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685725, content_id: 5e382118-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685725, content_id: "5e382118-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:55:41 UTC" },

      # base_path: /government/world-location-news/173338.uk, content_store: live
      # keeping id: 345730, content_id: 5e3855aa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685734, content_id: 5e3855aa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685734, content_id: "5e3855aa-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:55:50 UTC" },

      # base_path: /government/world-location-news/173355.ru, content_store: live
      # keeping id: 345731, content_id: 5e385b50-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685736, content_id: 5e385b50-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:55:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685736, content_id: "5e385b50-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:55:52 UTC" },

      # base_path: /government/world-location-news/173577.pt, content_store: live
      # keeping id: 404312, content_id: 5e38d2dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685748, content_id: 5e38d2dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685748, content_id: "5e38d2dc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:56:15 UTC" },

      # base_path: /government/world-location-news/173707.es, content_store: live
      # keeping id: 404313, content_id: 5e3914f7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685755, content_id: 5e3914f7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685755, content_id: "5e3914f7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:56:30 UTC" },

      # base_path: /government/world-location-news/173801.es-419, content_store: live
      # keeping id: 285879, content_id: 5e3936d1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685759, content_id: 5e3936d1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685759, content_id: "5e3936d1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:56:41 UTC" },

      # base_path: /government/world-location-news/173928.fr, content_store: live
      # keeping id: 404314, content_id: 5e39794e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685766, content_id: 5e39794e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:56:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685766, content_id: "5e39794e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:56:54 UTC" },

      # base_path: /government/world-location-news/173989.fa, content_store: live
      # keeping id: 345732, content_id: 5e39a437-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:57:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685773, content_id: 5e39a437-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:57:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685773, content_id: "5e39a437-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:57:01 UTC" },

      # base_path: /government/world-location-news/174063.pt, content_store: draft
      # keeping id: 685784, content_id: 5e39bf9f-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:57:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685783, content_id: 5e39bf9f-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:57:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685783, content_id: "5e39bf9f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:57:09 UTC" },

      # base_path: /government/world-location-news/174063.pt, content_store: live
      # keeping id: 285880, content_id: 5e39bf9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:57:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685781, content_id: 5e39bf9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:57:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685781, content_id: "5e39bf9f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:57:08 UTC" },

      # base_path: /government/world-location-news/174342.es-419, content_store: live
      # keeping id: 404315, content_id: 5e3a4c45-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:57:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685802, content_id: 5e3a4c45-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:57:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685802, content_id: "5e3a4c45-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:57:37 UTC" },

      # base_path: /government/world-location-news/174628.es-419, content_store: draft
      # keeping id: 685831, content_id: 5e5aedca-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:58:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685830, content_id: 5e5aedca-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 14:58:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685830, content_id: "5e5aedca-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:58:08 UTC" },

      # base_path: /government/world-location-news/174628.es-419, content_store: live
      # keeping id: 345733, content_id: 5e5aedca-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685829, content_id: 5e5aedca-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685829, content_id: "5e5aedca-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:58:07 UTC" },

      # base_path: /government/world-location-news/174914.es-419, content_store: live
      # keeping id: 404316, content_id: 5e5b8839-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685851, content_id: 5e5b8839-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685851, content_id: "5e5b8839-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:58:39 UTC" },

      # base_path: /government/world-location-news/174916.es-419, content_store: live
      # keeping id: 285881, content_id: 5e5b88e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685852, content_id: 5e5b88e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685852, content_id: "5e5b88e2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:58:39 UTC" },

      # base_path: /government/world-location-news/175060.zh-tw, content_store: live
      # keeping id: 285882, content_id: 5e5be23a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685872, content_id: 5e5be23a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685872, content_id: "5e5be23a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:58:53 UTC" },

      # base_path: /government/world-location-news/175082.es, content_store: live
      # keeping id: 404317, content_id: 5e5bf0fe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685874, content_id: 5e5bf0fe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:56 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685874, content_id: "5e5bf0fe-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:58:56 UTC" },

      # base_path: /government/world-location-news/175092.es, content_store: live
      # keeping id: 345734, content_id: 5e5bff1d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685875, content_id: 5e5bff1d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:58:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685875, content_id: "5e5bff1d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:58:57 UTC" },

      # base_path: /government/world-location-news/175196.lt, content_store: live
      # keeping id: 285883, content_id: 5e5c2ed7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685892, content_id: 5e5c2ed7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685892, content_id: "5e5c2ed7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:07 UTC" },

      # base_path: /government/world-location-news/175208.es, content_store: live
      # keeping id: 345735, content_id: 5e5c34bb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685893, content_id: 5e5c34bb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685893, content_id: "5e5c34bb-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:08 UTC" },

      # base_path: /government/world-location-news/175233.es, content_store: live
      # keeping id: 404318, content_id: 5e5c51e4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685895, content_id: 5e5c51e4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685895, content_id: "5e5c51e4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:11 UTC" },

      # base_path: /government/world-location-news/175313.es-419, content_store: live
      # keeping id: 404319, content_id: 5e5c7063-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:19 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685903, content_id: 5e5c7063-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685903, content_id: "5e5c7063-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:19 UTC" },

      # base_path: /government/world-location-news/175426.es-419, content_store: live
      # keeping id: 404320, content_id: 5e5cae7d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685916, content_id: 5e5cae7d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685916, content_id: "5e5cae7d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:29 UTC" },

      # base_path: /government/world-location-news/175432.pt, content_store: live
      # keeping id: 404321, content_id: 5e5cb188-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:30 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685920, content_id: 5e5cb188-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685920, content_id: "5e5cb188-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:30 UTC" },

      # base_path: /government/world-location-news/175433.es-419, content_store: live
      # keeping id: 404322, content_id: 5e5cb206-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:30 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685921, content_id: 5e5cb206-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685921, content_id: "5e5cb206-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:30 UTC" },

      # base_path: /government/world-location-news/175441.lt, content_store: live
      # keeping id: 345736, content_id: 5e5cb4b2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685922, content_id: 5e5cb4b2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 14:59:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685922, content_id: "5e5cb4b2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 14:59:30 UTC" },

      # base_path: /government/world-location-news/175727.es-419, content_store: live
      # keeping id: 404323, content_id: 5e5d4bf5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685937, content_id: 5e5d4bf5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685937, content_id: "5e5d4bf5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:00 UTC" },

      # base_path: /government/world-location-news/175737.lt, content_store: live
      # keeping id: 285884, content_id: 5e5d4f31-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685939, content_id: 5e5d4f31-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685939, content_id: "5e5d4f31-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:01 UTC" },

      # base_path: /government/world-location-news/175818.es-419, content_store: live
      # keeping id: 404324, content_id: 5e5d8149-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685945, content_id: 5e5d8149-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685945, content_id: "5e5d8149-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:11 UTC" },

      # base_path: /government/world-location-news/175840.zh-tw, content_store: live
      # keeping id: 285885, content_id: 5e5d8e5a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685946, content_id: 5e5d8e5a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685946, content_id: "5e5d8e5a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:13 UTC" },

      # base_path: /government/world-location-news/176020.ar, content_store: live
      # keeping id: 685966, content_id: 5e5de51a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404325, content_id: 5e5de51a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404325, content_id: "5e5de51a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:31 UTC" },

      # base_path: /government/world-location-news/176080.pt, content_store: live
      # keeping id: 345737, content_id: 5e5e1404-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685968, content_id: 5e5e1404-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685968, content_id: "5e5e1404-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:37 UTC" },

      # base_path: /government/world-location-news/176196.es, content_store: live
      # keeping id: 404326, content_id: 5e5e459d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685975, content_id: 5e5e459d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685975, content_id: "5e5e459d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:48 UTC" },

      # base_path: /government/world-location-news/176254.es-419, content_store: live
      # keeping id: 285886, content_id: 5e5e6943-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685980, content_id: 5e5e6943-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685980, content_id: "5e5e6943-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:53 UTC" },

      # base_path: /government/world-location-news/176281.ur, content_store: live
      # keeping id: 345738, content_id: 5e5e72cf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685987, content_id: 5e5e72cf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:00:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685987, content_id: "5e5e72cf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:00:57 UTC" },

      # base_path: /government/world-location-news/176480.it, content_store: live
      # keeping id: 404327, content_id: 5e5e80b7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:01:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685991, content_id: 5e5e80b7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:01:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685991, content_id: "5e5e80b7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:01:00 UTC" },

      # base_path: /government/world-location-news/176496.es-419, content_store: live
      # keeping id: 404328, content_id: 5e5e81b6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:01:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 685993, content_id: 5e5e81b6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:01:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 685993, content_id: "5e5e81b6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:01:01 UTC" },

      # base_path: /government/world-location-news/178953.zh-tw, content_store: draft
      # keeping id: 686031, content_id: 5e607e32-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:02:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686030, content_id: 5e607e32-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:02:18 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686030, content_id: "5e607e32-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:18 UTC" },

      # base_path: /government/world-location-news/178953.zh-tw, content_store: live
      # keeping id: 404329, content_id: 5e607e32-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686028, content_id: 5e607e32-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686028, content_id: "5e607e32-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:17 UTC" },

      # base_path: /government/world-location-news/179003.pt, content_store: live
      # keeping id: 404330, content_id: 5e609203-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686035, content_id: 5e609203-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686035, content_id: "5e609203-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:21 UTC" },

      # base_path: /government/world-location-news/179024.lt, content_store: live
      # keeping id: 404331, content_id: 5e609aad-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:24 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686036, content_id: 5e609aad-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:23 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686036, content_id: "5e609aad-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:23 UTC" },

      # base_path: /government/world-location-news/179074.pt, content_store: live
      # keeping id: 404332, content_id: 5e60b12d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:28 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686038, content_id: 5e60b12d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686038, content_id: "5e60b12d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:28 UTC" },

      # base_path: /government/world-location-news/179097.es, content_store: draft
      # keeping id: 686046, content_id: 5e60ca8e-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:02:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686045, content_id: 5e60ca8e-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:02:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686045, content_id: "5e60ca8e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:31 UTC" },

      # base_path: /government/world-location-news/179097.es, content_store: live
      # keeping id: 345739, content_id: 5e60ca8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686039, content_id: 5e60ca8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686039, content_id: "5e60ca8e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:30 UTC" },

      # base_path: /government/world-location-news/179098.es-419, content_store: live
      # keeping id: 285887, content_id: 5e60cade-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686041, content_id: 5e60cade-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686041, content_id: "5e60cade-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:30 UTC" },

      # base_path: /government/world-location-news/179099.pt, content_store: live
      # keeping id: 345740, content_id: 5e60cb3c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686040, content_id: 5e60cb3c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686040, content_id: "5e60cb3c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:30 UTC" },

      # base_path: /government/world-location-news/179127.cs, content_store: live
      # keeping id: 686047, content_id: 5e60d41d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404333, content_id: 5e60d41d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404333, content_id: "5e60d41d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:34 UTC" },

      # base_path: /government/world-location-news/179150.pt, content_store: live
      # keeping id: 404334, content_id: 5e60de38-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686049, content_id: 5e60de38-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:02:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686049, content_id: "5e60de38-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:02:37 UTC" },

      # base_path: /government/world-location-news/179503.zh-tw, content_store: draft
      # keeping id: 686081, content_id: 5e6459f7-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:03:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686080, content_id: 5e6459f7-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:03:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686080, content_id: "5e6459f7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:03:14 UTC" },

      # base_path: /government/world-location-news/179503.zh-tw, content_store: live
      # keeping id: 404335, content_id: 5e6459f7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686075, content_id: 5e6459f7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686075, content_id: "5e6459f7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:03:13 UTC" },

      # base_path: /government/world-location-news/179512.es-419, content_store: draft
      # keeping id: 686083, content_id: 5e646683-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:03:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686082, content_id: 5e646683-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:03:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686082, content_id: "5e646683-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:03:15 UTC" },

      # base_path: /government/world-location-news/179512.es-419, content_store: live
      # keeping id: 345741, content_id: 5e646683-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686077, content_id: 5e646683-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686077, content_id: "5e646683-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:03:14 UTC" },

      # base_path: /government/world-location-news/179513.es-419, content_store: live
      # keeping id: 345742, content_id: 5e646937-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686079, content_id: 5e646937-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686079, content_id: "5e646937-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:03:14 UTC" },

      # base_path: /government/world-location-news/179566.cs, content_store: live
      # keeping id: 686089, content_id: 5e64826c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285888, content_id: 5e64826c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:03:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285888, content_id: "5e64826c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:03:19 UTC" },

      # base_path: /government/world-location-news/180582.pt, content_store: live
      # keeping id: 404336, content_id: 5e66d046-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:04:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686134, content_id: 5e66d046-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:04:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686134, content_id: "5e66d046-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:04:51 UTC" },

      # base_path: /government/world-location-news/181967.ar, content_store: live
      # keeping id: 686148, content_id: 5e89baf2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:05:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345743, content_id: 5e89baf2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:05:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345743, content_id: "5e89baf2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:05:01 UTC" },

      # base_path: /government/world-location-news/182363.es, content_store: live
      # keeping id: 285889, content_id: 5e89cbc8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:05:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686153, content_id: 5e89cbc8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:05:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686153, content_id: "5e89cbc8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:05:06 UTC" },

      # base_path: /government/world-location-news/183869.es-419, content_store: live
      # keeping id: 404337, content_id: 5e89e947-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:05:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686170, content_id: 5e89e947-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:05:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686170, content_id: "5e89e947-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:05:11 UTC" },

      # base_path: /government/world-location-news/186091.pt, content_store: live
      # keeping id: 404338, content_id: 5e8caf03-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686254, content_id: 5e8caf03-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686254, content_id: "5e8caf03-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:06:44 UTC" },

      # base_path: /government/world-location-news/186101.cs, content_store: live
      # keeping id: 686255, content_id: 5e8cb23c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404339, content_id: 5e8cb23c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404339, content_id: "5e8cb23c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:06:45 UTC" },

      # base_path: /government/world-location-news/186178.es-419, content_store: live
      # keeping id: 285890, content_id: 5e8cf0b3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686267, content_id: 5e8cf0b3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686267, content_id: "5e8cf0b3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:06:53 UTC" },

      # base_path: /government/world-location-news/186212.zh-tw, content_store: live
      # keeping id: 345744, content_id: 5e8d0b10-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686270, content_id: 5e8d0b10-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:06:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686270, content_id: "5e8d0b10-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:06:57 UTC" },

      # base_path: /government/world-location-news/186354.it, content_store: live
      # keeping id: 285891, content_id: 5e8d599b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686285, content_id: 5e8d599b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686285, content_id: "5e8d599b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:07:09 UTC" },

      # base_path: /government/world-location-news/186407.it, content_store: live
      # keeping id: 345745, content_id: 5e8d702a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686290, content_id: 5e8d702a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686290, content_id: "5e8d702a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:07:14 UTC" },

      # base_path: /government/world-location-news/186484.cs, content_store: live
      # keeping id: 686295, content_id: 5e8da15c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404340, content_id: 5e8da15c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404340, content_id: "5e8da15c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:07:22 UTC" },

      # base_path: /government/world-location-news/186635.ar, content_store: live
      # keeping id: 686302, content_id: 5e8df215-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404341, content_id: 5e8df215-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:07:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404341, content_id: "5e8df215-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:07:37 UTC" },

      # base_path: /government/world-location-news/188107.ar, content_store: live
      # keeping id: 686322, content_id: 5e8fc887-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:08:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345746, content_id: 5e8fc887-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:08:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345746, content_id: "5e8fc887-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:08:50 UTC" },

      # base_path: /government/world-location-news/188215.lt, content_store: live
      # keeping id: 345747, content_id: 5e90019c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686332, content_id: 5e90019c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:02 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686332, content_id: "5e90019c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:02 UTC" },

      # base_path: /government/world-location-news/188230.pt, content_store: live
      # keeping id: 345711, content_id: 5e900e6c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686335, content_id: 5e900e6c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686335, content_id: "5e900e6c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:03 UTC" },

      # base_path: /government/world-location-news/188291.cs, content_store: live
      # keeping id: 686341, content_id: 5e902722-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404342, content_id: 5e902722-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404342, content_id: "5e902722-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:10 UTC" },

      # base_path: /government/world-location-news/188385.lt, content_store: draft
      # keeping id: 686348, content_id: 5e905f44-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:09:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686347, content_id: 5e905f44-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:09:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686347, content_id: "5e905f44-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:21 UTC" },

      # base_path: /government/world-location-news/188385.lt, content_store: live
      # keeping id: 404343, content_id: 5e905f44-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686345, content_id: 5e905f44-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686345, content_id: "5e905f44-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:20 UTC" },

      # base_path: /government/world-location-news/188434.lt, content_store: live
      # keeping id: 404344, content_id: 5e92a84f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686352, content_id: 5e92a84f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686352, content_id: "5e92a84f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:25 UTC" },

      # base_path: /government/world-location-news/188483.pt, content_store: live
      # keeping id: 404345, content_id: 5e92c912-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686360, content_id: 5e92c912-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686360, content_id: "5e92c912-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:30 UTC" },

      # base_path: /government/world-location-news/188497.ar, content_store: live
      # keeping id: 686366, content_id: 5e92e335-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285892, content_id: 5e92e335-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285892, content_id: "5e92e335-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:31 UTC" },

      # base_path: /government/world-location-news/188502.zh-tw, content_store: live
      # keeping id: 345748, content_id: 5e92e547-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686365, content_id: 5e92e547-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:32 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686365, content_id: "5e92e547-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:32 UTC" },

      # base_path: /government/world-location-news/188638.ru, content_store: live
      # keeping id: 238102, content_id: 5e932db3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686385, content_id: 5e932db3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686385, content_id: "5e932db3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:48 UTC" },

      # base_path: /government/world-location-news/188643.he, content_store: live
      # keeping id: 285893, content_id: 5e932f71-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686386, content_id: 5e932f71-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686386, content_id: "5e932f71-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:48 UTC" },

      # base_path: /government/world-location-news/189734.zh-tw, content_store: live
      # keeping id: 404346, content_id: 5e93483c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686391, content_id: 5e93483c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686391, content_id: "5e93483c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:54 UTC" },

      # base_path: /government/world-location-news/189739.zh-tw, content_store: live
      # keeping id: 285894, content_id: 5e934a25-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686392, content_id: 5e934a25-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686392, content_id: "5e934a25-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:55 UTC" },

      # base_path: /government/world-location-news/190265.ja, content_store: live
      # keeping id: 345750, content_id: 5e934d6c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686395, content_id: 5e934d6c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:09:56 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686395, content_id: "5e934d6c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:09:56 UTC" },

      # base_path: /government/world-location-news/191838.it, content_store: live
      # keeping id: 404348, content_id: 5e94802b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:10:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686410, content_id: 5e94802b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:10:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686410, content_id: "5e94802b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:10:43 UTC" },

      # base_path: /government/world-location-news/191926.it, content_store: live
      # keeping id: 404349, content_id: 5e94a19d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:10:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686415, content_id: 5e94a19d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:10:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686415, content_id: "5e94a19d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:10:52 UTC" },

      # base_path: /government/world-location-news/192069.pt, content_store: live
      # keeping id: 285895, content_id: 5e94ee8b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686428, content_id: 5e94ee8b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686428, content_id: "5e94ee8b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:11:07 UTC" },

      # base_path: /government/world-location-news/192094.es, content_store: live
      # keeping id: 404350, content_id: 5e94f8f0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686431, content_id: 5e94f8f0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686431, content_id: "5e94f8f0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:11:10 UTC" },

      # base_path: /government/world-location-news/192253.he, content_store: live
      # keeping id: 404351, content_id: 5e95501d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686446, content_id: 5e95501d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:27 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686446, content_id: "5e95501d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:11:27 UTC" },

      # base_path: /government/world-location-news/192269.ar, content_store: live
      # keeping id: 686447, content_id: 5e956569-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:30 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345751, content_id: 5e956569-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345751, content_id: "5e956569-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:11:28 UTC" },

      # base_path: /government/world-location-news/192303.es, content_store: live
      # keeping id: 238103, content_id: 5e9570ff-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:33 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686451, content_id: 5e9570ff-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686451, content_id: "5e9570ff-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:11:33 UTC" },

      # base_path: /government/world-location-news/192401.es-419, content_store: live
      # keeping id: 404352, content_id: 5e95a527-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686459, content_id: 5e95a527-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:11:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686459, content_id: "5e95a527-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:11:41 UTC" },

      # base_path: /government/world-location-news/192620.es-419, content_store: live
      # keeping id: 404353, content_id: 5e96132f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686488, content_id: 5e96132f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686488, content_id: "5e96132f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:05 UTC" },

      # base_path: /government/world-location-news/192676.pt, content_store: live
      # keeping id: 404354, content_id: 5e9635dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686491, content_id: 5e9635dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686491, content_id: "5e9635dc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:11 UTC" },

      # base_path: /government/world-location-news/192706.pt, content_store: live
      # keeping id: 285896, content_id: 5e96480c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686495, content_id: 5e96480c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686495, content_id: "5e96480c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:14 UTC" },

      # base_path: /government/world-location-news/192707.es-419, content_store: live
      # keeping id: 404355, content_id: 5e96485c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686496, content_id: 5e96485c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686496, content_id: "5e96485c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:15 UTC" },

      # base_path: /government/world-location-news/192723.ja, content_store: draft
      # keeping id: 686498, content_id: 5e964e34-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:12:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686497, content_id: 5e964e34-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:12:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686497, content_id: "5e964e34-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:16 UTC" },

      # base_path: /government/world-location-news/192763.pt, content_store: live
      # keeping id: 404356, content_id: 5e965d29-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686506, content_id: 5e965d29-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686506, content_id: "5e965d29-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:21 UTC" },

      # base_path: /government/world-location-news/192841.zh-tw, content_store: live
      # keeping id: 345752, content_id: 5e968ebf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686520, content_id: 5e968ebf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686520, content_id: "5e968ebf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:29 UTC" },

      # base_path: /government/world-location-news/192952.es-419, content_store: live
      # keeping id: 285897, content_id: 5e96c0c2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686529, content_id: 5e96c0c2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:12:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686529, content_id: "5e96c0c2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:12:39 UTC" },

      # base_path: /government/world-location-news/193179.ur, content_store: live
      # keeping id: 404357, content_id: 5e973eb8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:13:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686555, content_id: 5e973eb8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:13:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686555, content_id: "5e973eb8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:13:03 UTC" },

      # base_path: /government/world-location-news/193191.it, content_store: live
      # keeping id: 404358, content_id: 5e974285-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:13:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686557, content_id: 5e974285-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:13:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686557, content_id: "5e974285-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:13:04 UTC" },

      # base_path: /government/world-location-news/197155.pl, content_store: live
      # keeping id: 345753, content_id: 5e9bf354-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:15:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686636, content_id: 5e9bf354-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:15:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686636, content_id: "5e9bf354-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:15:55 UTC" },

      # base_path: /government/world-location-news/197196.es, content_store: live
      # keeping id: 345754, content_id: 5e9c0584-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686638, content_id: 5e9c0584-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:15:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686638, content_id: "5e9c0584-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:15:59 UTC" },

      # base_path: /government/world-location-news/197264.es, content_store: live
      # keeping id: 285898, content_id: 5e9c31c1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686646, content_id: 5e9c31c1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686646, content_id: "5e9c31c1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:16:07 UTC" },

      # base_path: /government/world-location-news/197273.ru, content_store: live
      # keeping id: 345755, content_id: 5e9c360e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686648, content_id: 5e9c360e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686648, content_id: "5e9c360e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:16:08 UTC" },

      # base_path: /government/world-location-news/197379.zh-tw, content_store: live
      # keeping id: 285899, content_id: 5e9c73b5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686659, content_id: 5e9c73b5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686659, content_id: "5e9c73b5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:16:19 UTC" },

      # base_path: /government/world-location-news/197500.es, content_store: live
      # keeping id: 345756, content_id: 5e9caf6d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:33 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686669, content_id: 5e9caf6d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686669, content_id: "5e9caf6d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:16:33 UTC" },

      # base_path: /government/world-location-news/197638.pt, content_store: live
      # keeping id: 404359, content_id: 5e9cf64d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686677, content_id: 5e9cf64d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686677, content_id: "5e9cf64d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:16:47 UTC" },

      # base_path: /government/world-location-news/197692.es, content_store: live
      # keeping id: 404360, content_id: 5e9d16a3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686680, content_id: 5e9d16a3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686680, content_id: "5e9d16a3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:16:53 UTC" },

      # base_path: /government/world-location-news/197735.es-419, content_store: live
      # keeping id: 285900, content_id: 5e9d26fe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686683, content_id: 5e9d26fe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:16:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686683, content_id: "5e9d26fe-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:16:58 UTC" },

      # base_path: /government/world-location-news/197760.ar, content_store: live
      # keeping id: 686686, content_id: 5e9d3062-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404361, content_id: 5e9d3062-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404361, content_id: "5e9d3062-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:17:01 UTC" },

      # base_path: /government/world-location-news/197833.es-419, content_store: live
      # keeping id: 345757, content_id: 5e9d6113-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686690, content_id: 5e9d6113-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686690, content_id: "5e9d6113-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:17:10 UTC" },

      # base_path: /government/world-location-news/197856.zh-tw, content_store: live
      # keeping id: 345758, content_id: 5e9d6b55-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686694, content_id: 5e9d6b55-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686694, content_id: "5e9d6b55-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:17:12 UTC" },

      # base_path: /government/world-location-news/197857.zh-tw, content_store: draft
      # keeping id: 686697, content_id: 5e9d6ba0-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:17:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686693, content_id: 5e9d6ba0-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:17:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686693, content_id: "5e9d6ba0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:17:12 UTC" },

      # base_path: /government/world-location-news/197866.lt, content_store: live
      # keeping id: 285901, content_id: 5e9d6e84-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686696, content_id: 5e9d6e84-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686696, content_id: "5e9d6e84-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:17:14 UTC" },

      # base_path: /government/world-location-news/197991.lt, content_store: live
      # keeping id: 404362, content_id: 5e9db40b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 686704, content_id: 5e9db40b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:17:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 686704, content_id: "5e9db40b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:17:26 UTC" },

      # base_path: /government/world-location-news/200705.es-419, content_store: live
      # keeping id: 404364, content_id: 5eb95063-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:22:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688045, content_id: 5eb95063-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:22:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688045, content_id: "5eb95063-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:22:41 UTC" },

      # base_path: /government/world-location-news/200721.ja, content_store: live
      # keeping id: 404365, content_id: 5eb9553e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:22:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688049, content_id: 5eb9553e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:22:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688049, content_id: "5eb9553e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:22:43 UTC" },

      # base_path: /government/world-location-news/200799.fr, content_store: live
      # keeping id: 404366, content_id: 5eb99351-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:22:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688055, content_id: 5eb99351-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:22:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688055, content_id: "5eb99351-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:22:50 UTC" },

      # base_path: /government/world-location-news/200903.de, content_store: live
      # keeping id: 688063, content_id: 5eb9beff-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345760, content_id: 5eb9beff-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345760, content_id: "5eb9beff-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:23:00 UTC" },

      # base_path: /government/world-location-news/200905.el, content_store: live
      # keeping id: 688065, content_id: 5eb9c1a1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404367, content_id: 5eb9c1a1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404367, content_id: "5eb9c1a1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:23:00 UTC" },

      # base_path: /government/world-location-news/201030.it, content_store: live
      # keeping id: 345762, content_id: 5eba0176-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688074, content_id: 5eba0176-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688074, content_id: "5eba0176-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:23:15 UTC" },

      # base_path: /government/world-location-news/201192.pt, content_store: live
      # keeping id: 285902, content_id: 5eba63bc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688095, content_id: 5eba63bc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688095, content_id: "5eba63bc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:23:31 UTC" },

      # base_path: /government/world-location-news/201393.es, content_store: live
      # keeping id: 404371, content_id: 5ebad54f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688116, content_id: 5ebad54f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688116, content_id: "5ebad54f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:23:52 UTC" },

      # base_path: /government/world-location-news/201405.it, content_store: live
      # keeping id: 345772, content_id: 5ebadbcd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688118, content_id: 5ebadbcd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688118, content_id: "5ebadbcd-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:23:54 UTC" },

      # base_path: /government/world-location-news/201421.pt, content_store: live
      # keeping id: 285909, content_id: 5ebae0f5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688120, content_id: 5ebae0f5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:23:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688120, content_id: "5ebae0f5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:23:55 UTC" },

      # base_path: /government/world-location-news/201650.fr, content_store: live
      # keeping id: 285916, content_id: 5ebcee41-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688146, content_id: 5ebcee41-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688146, content_id: "5ebcee41-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:24:20 UTC" },

      # base_path: /government/world-location-news/201656.es-419, content_store: live
      # keeping id: 404389, content_id: 5ebcf041-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688147, content_id: 5ebcf041-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688147, content_id: "5ebcf041-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:24:21 UTC" },

      # base_path: /government/world-location-news/201788.de, content_store: live
      # keeping id: 688158, content_id: 5ebd3977-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:36 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345780, content_id: 5ebd3977-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345780, content_id: "5ebd3977-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:24:35 UTC" },

      # base_path: /government/world-location-news/201804.cs, content_store: live
      # keeping id: 688161, content_id: 5ebd3fa4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 238104, content_id: 5ebd3fa4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 238104, content_id: "5ebd3fa4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:24:37 UTC" },

      # base_path: /government/world-location-news/201813.fr, content_store: live
      # keeping id: 345781, content_id: 5ebd4433-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688163, content_id: 5ebd4433-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688163, content_id: "5ebd4433-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:24:38 UTC" },

      # base_path: /government/world-location-news/201932.pt, content_store: live
      # keeping id: 285917, content_id: 5ebd87b9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688175, content_id: 5ebd87b9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:24:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688175, content_id: "5ebd87b9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:24:49 UTC" },

      # base_path: /government/world-location-news/202126.ja, content_store: live
      # keeping id: 404391, content_id: 5ebde852-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:25:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688195, content_id: 5ebde852-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:25:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688195, content_id: "5ebde852-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:25:10 UTC" },

      # base_path: /government/world-location-news/202481.es-419, content_store: live
      # keeping id: 404392, content_id: 5ebeae57-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:25:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688262, content_id: 5ebeae57-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:25:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688262, content_id: "5ebeae57-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:25:42 UTC" },

      # base_path: /government/world-location-news/202675.pt, content_store: draft
      # keeping id: 688281, content_id: 5ebf0d77-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:26:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688280, content_id: 5ebf0d77-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:26:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688280, content_id: "5ebf0d77-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:26:03 UTC" },

      # base_path: /government/world-location-news/202702.ru, content_store: live
      # keeping id: 345782, content_id: 5ebf179a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:26:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688282, content_id: 5ebf179a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:26:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688282, content_id: "5ebf179a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:26:06 UTC" },

      # base_path: /government/world-location-news/203079.es, content_store: live
      # keeping id: 404394, content_id: 5ebfe272-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:26:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688321, content_id: 5ebfe272-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:26:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688321, content_id: "5ebfe272-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:26:44 UTC" },

      # base_path: /government/world-location-news/203151.es, content_store: live
      # keeping id: 345783, content_id: 5ebffe45-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:26:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688329, content_id: 5ebffe45-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:26:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688329, content_id: "5ebffe45-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:26:52 UTC" },

      # base_path: /government/world-location-news/203257.fr, content_store: live
      # keeping id: 404395, content_id: 5ec03d42-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:27:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688345, content_id: 5ec03d42-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:27:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688345, content_id: "5ec03d42-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:27:03 UTC" },

      # base_path: /government/world-location-news/203276.zh-tw, content_store: draft
      # keeping id: 688350, content_id: 5ec04332-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:27:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688349, content_id: 5ec04332-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:27:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688349, content_id: "5ec04332-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:27:06 UTC" },

      # base_path: /government/world-location-news/203276.zh-tw, content_store: live
      # keeping id: 404396, content_id: 5ec04332-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:27:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688348, content_id: 5ec04332-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:27:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688348, content_id: "5ec04332-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:27:05 UTC" },

      # base_path: /government/world-location-news/203338.es, content_store: live
      # keeping id: 345784, content_id: 5ec06e9b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:27:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688359, content_id: 5ec06e9b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:27:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688359, content_id: "5ec06e9b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:27:11 UTC" },

      # base_path: /government/world-location-news/206678.es-419, content_store: live
      # keeping id: 345785, content_id: 5ec3afc4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:28:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688642, content_id: 5ec3afc4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:28:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688642, content_id: "5ec3afc4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:28:34 UTC" },

      # base_path: /government/world-location-news/206719.es, content_store: live
      # keeping id: 404397, content_id: 5ec3c404-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:28:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688646, content_id: 5ec3c404-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:28:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688646, content_id: "5ec3c404-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:28:39 UTC" },

      # base_path: /government/world-location-news/206840.es-419, content_store: live
      # keeping id: 404398, content_id: 5ec407bc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:28:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688668, content_id: 5ec407bc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:28:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688668, content_id: "5ec407bc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:28:51 UTC" },

      # base_path: /government/world-location-news/207012.pt, content_store: live
      # keeping id: 285919, content_id: 5ec462ba-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688707, content_id: 5ec462ba-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688707, content_id: "5ec462ba-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:11 UTC" },

      # base_path: /government/world-location-news/207014.pt, content_store: live
      # keeping id: 404399, content_id: 5ec46361-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688708, content_id: 5ec46361-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688708, content_id: "5ec46361-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:11 UTC" },

      # base_path: /government/world-location-news/207015.pt, content_store: live
      # keeping id: 404400, content_id: 5ec463ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688709, content_id: 5ec463ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688709, content_id: "5ec463ab-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:11 UTC" },

      # base_path: /government/world-location-news/207016.pt, content_store: live
      # keeping id: 345786, content_id: 5ec46403-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688710, content_id: 5ec46403-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688710, content_id: "5ec46403-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:11 UTC" },

      # base_path: /government/world-location-news/208137.es-419, content_store: live
      # keeping id: 345787, content_id: 5ec6ae2d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688723, content_id: 5ec6ae2d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:27 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688723, content_id: "5ec6ae2d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:27 UTC" },

      # base_path: /government/world-location-news/208245.fr, content_store: live
      # keeping id: 345788, content_id: 5ee3db84-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688737, content_id: 5ee3db84-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688737, content_id: "5ee3db84-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:37 UTC" },

      # base_path: /government/world-location-news/208332.el, content_store: live
      # keeping id: 688747, content_id: 5ee4095f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:47 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285920, content_id: 5ee4095f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:46 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285920, content_id: "5ee4095f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:46 UTC" },

      # base_path: /government/world-location-news/208365.ar, content_store: live
      # keeping id: 688750, content_id: 5ee422ec-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345789, content_id: 5ee422ec-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345789, content_id: "5ee422ec-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:49 UTC" },

      # base_path: /government/world-location-news/208464.lt, content_store: live
      # keeping id: 285921, content_id: 5ee4505c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:30:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688755, content_id: 5ee4505c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:29:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688755, content_id: "5ee4505c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:29:59 UTC" },

      # base_path: /government/world-location-news/208807.es, content_store: live
      # keeping id: 404401, content_id: 5ee4fd08-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:30:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688785, content_id: 5ee4fd08-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:30:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688785, content_id: "5ee4fd08-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:30:33 UTC" },

      # base_path: /government/world-location-news/209141.zh-tw, content_store: live
      # keeping id: 285922, content_id: 5ee59f52-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688837, content_id: 5ee59f52-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:02 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688837, content_id: "5ee59f52-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:31:02 UTC" },

      # base_path: /government/world-location-news/209249.it, content_store: live
      # keeping id: 285923, content_id: 5ee5da9c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688856, content_id: 5ee5da9c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688856, content_id: "5ee5da9c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:31:15 UTC" },

      # base_path: /government/world-location-news/209252.pt, content_store: live
      # keeping id: 345790, content_id: 5ee5dc47-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688858, content_id: 5ee5dc47-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688858, content_id: "5ee5dc47-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:31:15 UTC" },

      # base_path: /government/world-location-news/209261.pt, content_store: live
      # keeping id: 404402, content_id: 5ee5e0b8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688859, content_id: 5ee5e0b8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688859, content_id: "5ee5e0b8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:31:16 UTC" },

      # base_path: /government/world-location-news/209290.ru, content_store: live
      # keeping id: 345791, content_id: 5ee5e99d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688864, content_id: 5ee5e99d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688864, content_id: "5ee5e99d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:31:19 UTC" },

      # base_path: /government/world-location-news/209598.it, content_store: live
      # keeping id: 285924, content_id: 5ee684ff-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688907, content_id: 5ee684ff-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688907, content_id: "5ee684ff-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:31:54 UTC" },

      # base_path: /government/world-location-news/209605.de, content_store: live
      # keeping id: 688910, content_id: 5ee68a15-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285925, content_id: 5ee68a15-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:31:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285925, content_id: "5ee68a15-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:31:54 UTC" },

      # base_path: /government/world-location-news/209973.ar, content_store: live
      # keeping id: 688959, content_id: 5eef60fd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:32:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345792, content_id: 5eef60fd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:32:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345792, content_id: "5eef60fd-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:32:34 UTC" },

      # base_path: /government/world-location-news/210097.fr, content_store: live
      # keeping id: 345793, content_id: 5eefa179-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:32:47 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 688982, content_id: 5eefa179-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:32:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 688982, content_id: "5eefa179-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:32:47 UTC" },

      # base_path: /government/world-location-news/210373.pt, content_store: draft
      # keeping id: 689010, content_id: 5ef02db4-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:33:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689008, content_id: 5ef02db4-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 15:33:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689008, content_id: "5ef02db4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:08 UTC" },

      # base_path: /government/world-location-news/210374.es-419, content_store: live
      # keeping id: 345794, content_id: 5ef02e47-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689009, content_id: 5ef02e47-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689009, content_id: "5ef02e47-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:09 UTC" },

      # base_path: /government/world-location-news/210389.zh-tw, content_store: live
      # keeping id: 404403, content_id: 5ef036da-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689013, content_id: 5ef036da-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689013, content_id: "5ef036da-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:10 UTC" },

      # base_path: /government/world-location-news/210451.ar, content_store: live
      # keeping id: 689017, content_id: 5ef05c86-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345795, content_id: 5ef05c86-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345795, content_id: "5ef05c86-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:17 UTC" },

      # base_path: /government/world-location-news/210510.zh-tw, content_store: live
      # keeping id: 345796, content_id: 5ef07955-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:24 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689021, content_id: 5ef07955-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:23 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689021, content_id: "5ef07955-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:23 UTC" },

      # base_path: /government/world-location-news/210520.zh-tw, content_store: live
      # keeping id: 285926, content_id: 5ef07c49-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689024, content_id: 5ef07c49-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689024, content_id: "5ef07c49-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:25 UTC" },

      # base_path: /government/world-location-news/210535.es, content_store: live
      # keeping id: 404404, content_id: 5ef08654-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689026, content_id: 5ef08654-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:27 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689026, content_id: "5ef08654-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:27 UTC" },

      # base_path: /government/world-location-news/210578.lt, content_store: live
      # keeping id: 404406, content_id: 5ef09d29-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689032, content_id: 5ef09d29-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:32 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689032, content_id: "5ef09d29-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:32 UTC" },

      # base_path: /government/world-location-news/210686.zh-tw, content_store: live
      # keeping id: 404407, content_id: 5ef0d9be-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689039, content_id: 5ef0d9be-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:33:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689039, content_id: "5ef0d9be-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:33:44 UTC" },

      # base_path: /government/world-location-news/211480.pt, content_store: live
      # keeping id: 404408, content_id: 5ef41983-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689128, content_id: 5ef41983-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689128, content_id: "5ef41983-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:35:03 UTC" },

      # base_path: /government/world-location-news/211747.bg, content_store: live
      # keeping id: 689171, content_id: 5ef48e71-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:28 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285927, content_id: 5ef48e71-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:27 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285927, content_id: "5ef48e71-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:35:27 UTC" },

      # base_path: /government/world-location-news/211753.es-419, content_store: live
      # keeping id: 404409, content_id: 5ef4941e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:28 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689170, content_id: 5ef4941e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689170, content_id: "5ef4941e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:35:28 UTC" },

      # base_path: /government/world-location-news/211933.es, content_store: live
      # keeping id: 345797, content_id: 5ef500c0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689187, content_id: 5ef500c0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689187, content_id: "5ef500c0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:35:47 UTC" },

      # base_path: /government/world-location-news/212008.es-419, content_store: live
      # keeping id: 285928, content_id: 5ef51c9d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689196, content_id: 5ef51c9d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689196, content_id: "5ef51c9d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:35:55 UTC" },

      # base_path: /government/world-location-news/212013.es-419, content_store: live
      # keeping id: 404410, content_id: 5ef51e1b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689197, content_id: 5ef51e1b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689197, content_id: "5ef51e1b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:35:55 UTC" },

      # base_path: /government/world-location-news/212016.es-419, content_store: live
      # keeping id: 345798, content_id: 5ef52082-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689199, content_id: 5ef52082-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:35:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689199, content_id: "5ef52082-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:35:55 UTC" },

      # base_path: /government/world-location-news/212120.es-419, content_store: live
      # keeping id: 404411, content_id: 5ef55c86-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689211, content_id: 5ef55c86-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689211, content_id: "5ef55c86-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:36:07 UTC" },

      # base_path: /government/world-location-news/212142.pt, content_store: live
      # keeping id: 345799, content_id: 5ef56300-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689212, content_id: 5ef56300-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689212, content_id: "5ef56300-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:36:09 UTC" },

      # base_path: /government/world-location-news/212474.ja, content_store: live
      # keeping id: 345800, content_id: 5ef607e0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689268, content_id: 5ef607e0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689268, content_id: "5ef607e0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:36:42 UTC" },

      # base_path: /government/world-location-news/212549.ru, content_store: live
      # keeping id: 345801, content_id: 5ef63356-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689278, content_id: 5ef63356-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:36:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689278, content_id: "5ef63356-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:36:49 UTC" },

      # base_path: /government/world-location-news/212806.th, content_store: live
      # keeping id: 345802, content_id: 5ef6b66d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689321, content_id: 5ef6b66d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689321, content_id: "5ef6b66d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:37:16 UTC" },

      # base_path: /government/world-location-news/212818.es, content_store: live
      # keeping id: 285929, content_id: 5ef6bb95-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689322, content_id: 5ef6bb95-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:18 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689322, content_id: "5ef6bb95-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:37:18 UTC" },

      # base_path: /government/world-location-news/212994.es, content_store: live
      # keeping id: 345761, content_id: 5ef70f18-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:36 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689348, content_id: 5ef70f18-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689348, content_id: "5ef70f18-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:37:35 UTC" },

      # base_path: /government/world-location-news/213055.lt, content_store: live
      # keeping id: 404412, content_id: 5ef73bce-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689355, content_id: 5ef73bce-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689355, content_id: "5ef73bce-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:37:41 UTC" },

      # base_path: /government/world-location-news/213080.ur, content_store: live
      # keeping id: 345803, content_id: 5ef74419-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689359, content_id: 5ef74419-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:37:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689359, content_id: "5ef74419-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:37:44 UTC" },

      # base_path: /government/world-location-news/213279.ar, content_store: live
      # keeping id: 689389, content_id: 5ef7a3f4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404413, content_id: 5ef7a3f4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404413, content_id: "5ef7a3f4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:38:03 UTC" },

      # base_path: /government/world-location-news/213347.zh-tw, content_store: live
      # keeping id: 285930, content_id: 5ef7d44b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689393, content_id: 5ef7d44b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689393, content_id: "5ef7d44b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:38:11 UTC" },

      # base_path: /government/world-location-news/213493.es-419, content_store: live
      # keeping id: 345804, content_id: 5ef822d2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:28 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689412, content_id: 5ef822d2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689412, content_id: "5ef822d2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:38:28 UTC" },

      # base_path: /government/world-location-news/213614.es-419, content_store: live
      # keeping id: 345805, content_id: 5ef85197-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689422, content_id: 5ef85197-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:38:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689422, content_id: "5ef85197-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:38:40 UTC" },

      # base_path: /government/world-location-news/214930.pt, content_store: live
      # keeping id: 404414, content_id: 5efa0757-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689445, content_id: 5efa0757-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689445, content_id: "5efa0757-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:40:04 UTC" },

      # base_path: /government/world-location-news/215070.de, content_store: live
      # keeping id: 689464, content_id: 5efa4f0b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:19 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285931, content_id: 5efa4f0b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:18 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285931, content_id: "5efa4f0b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:40:18 UTC" },

      # base_path: /government/world-location-news/215108.es-419, content_store: live
      # keeping id: 345806, content_id: 5efa5ae5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689468, content_id: 5efa5ae5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:23 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689468, content_id: "5efa5ae5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:40:23 UTC" },

      # base_path: /government/world-location-news/215246.pt, content_store: live
      # keeping id: 404415, content_id: 5efaa278-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689490, content_id: 5efaa278-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689490, content_id: "5efaa278-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:40:38 UTC" },

      # base_path: /government/world-location-news/215309.es, content_store: live
      # keeping id: 345807, content_id: 5efacebf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689497, content_id: 5efacebf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689497, content_id: "5efacebf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:40:44 UTC" },

      # base_path: /government/world-location-news/215446.ja, content_store: live
      # keeping id: 404416, content_id: 5efb18fb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689518, content_id: 5efb18fb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689518, content_id: "5efb18fb-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:40:57 UTC" },

      # base_path: /government/world-location-news/215466.es, content_store: live
      # keeping id: 345808, content_id: 5efb1edd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689520, content_id: 5efb1edd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:40:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689520, content_id: "5efb1edd-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:40:59 UTC" },

      # base_path: /government/world-location-news/215484.es, content_store: live
      # keeping id: 345809, content_id: 5efb2530-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689524, content_id: 5efb2530-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689524, content_id: "5efb2530-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:01 UTC" },

      # base_path: /government/world-location-news/215515.de, content_store: live
      # keeping id: 689531, content_id: 5efb30ea-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404417, content_id: 5efb30ea-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404417, content_id: "5efb30ea-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:04 UTC" },

      # base_path: /government/world-location-news/215578.es-419, content_store: live
      # keeping id: 285932, content_id: 5efb53fc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689537, content_id: 5efb53fc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689537, content_id: "5efb53fc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:10 UTC" },

      # base_path: /government/world-location-news/215586.ko, content_store: live
      # keeping id: 404418, content_id: 5efb60cf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689539, content_id: 5efb60cf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689539, content_id: "5efb60cf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:11 UTC" },

      # base_path: /government/world-location-news/215616.es, content_store: live
      # keeping id: 285933, content_id: 5efb69aa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689544, content_id: 5efb69aa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689544, content_id: "5efb69aa-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:14 UTC" },

      # base_path: /government/world-location-news/215667.es, content_store: live
      # keeping id: 345810, content_id: 5efb7c36-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689555, content_id: 5efb7c36-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689555, content_id: "5efb7c36-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:19 UTC" },

      # base_path: /government/world-location-news/215682.it, content_store: live
      # keeping id: 345811, content_id: 5efb814f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689559, content_id: 5efb814f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689559, content_id: "5efb814f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:21 UTC" },

      # base_path: /government/world-location-news/215726.fr, content_store: live
      # keeping id: 285934, content_id: 5efb9fb0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689563, content_id: 5efb9fb0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689563, content_id: "5efb9fb0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:25 UTC" },

      # base_path: /government/world-location-news/215732.zh-tw, content_store: live
      # keeping id: 345812, content_id: 5efbad73-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689564, content_id: 5efbad73-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689564, content_id: "5efbad73-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:26 UTC" },

      # base_path: /government/world-location-news/216080.zh-tw, content_store: live
      # keeping id: 404419, content_id: 5efc43f9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689615, content_id: 5efc43f9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:41:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689615, content_id: "5efc43f9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:41:55 UTC" },

      # base_path: /government/world-location-news/216480.pt, content_store: live
      # keeping id: 404420, content_id: 5f1020c8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:42:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689648, content_id: 5f1020c8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:42:32 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689648, content_id: "5f1020c8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:42:32 UTC" },

      # base_path: /government/world-location-news/216573.pt, content_store: live
      # keeping id: 404421, content_id: 5f105b9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:42:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689654, content_id: 5f105b9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:42:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689654, content_id: "5f105b9f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:42:40 UTC" },

      # base_path: /government/world-location-news/216867.es-419, content_store: live
      # keeping id: 285935, content_id: 5f10f456-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:43:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689720, content_id: 5f10f456-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:43:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689720, content_id: "5f10f456-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:43:13 UTC" },

      # base_path: /government/world-location-news/216904.ru, content_store: live
      # keeping id: 285936, content_id: 5f1100e8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:43:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689724, content_id: 5f1100e8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:43:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689724, content_id: "5f1100e8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:43:20 UTC" },

      # base_path: /government/world-location-news/217375.es, content_store: live
      # keeping id: 285937, content_id: 5f120825-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:44:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689815, content_id: 5f120825-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:44:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689815, content_id: "5f120825-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:44:09 UTC" },

      # base_path: /government/world-location-news/217493.ru, content_store: live
      # keeping id: 404422, content_id: 5f123763-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:44:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689833, content_id: 5f123763-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:44:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689833, content_id: "5f123763-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:44:20 UTC" },

      # base_path: /government/world-location-news/217637.es-419, content_store: live
      # keeping id: 345813, content_id: 5f127e90-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:44:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689867, content_id: 5f127e90-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:44:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689867, content_id: "5f127e90-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:44:35 UTC" },

      # base_path: /government/world-location-news/217876.es, content_store: live
      # keeping id: 345814, content_id: 5f1301b6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:45:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689894, content_id: 5f1301b6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:45:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689894, content_id: "5f1301b6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:45:06 UTC" },

      # base_path: /government/world-location-news/218024.es-419, content_store: live
      # keeping id: 404423, content_id: 5f1348ed-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:45:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 689953, content_id: 5f1348ed-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:45:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 689953, content_id: "5f1348ed-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:45:25 UTC" },

      # base_path: /government/world-location-news/220114.zh-tw, content_store: live
      # keeping id: 404424, content_id: 5f157d23-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690098, content_id: 5f157d23-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690098, content_id: "5f157d23-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:47:25 UTC" },

      # base_path: /government/world-location-news/220227.ar, content_store: live
      # keeping id: 690125, content_id: 5f15bd4b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285938, content_id: 5f15bd4b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285938, content_id: "5f15bd4b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:47:38 UTC" },

      # base_path: /government/world-location-news/220268.lt, content_store: live
      # keeping id: 404425, content_id: 5f15cdd8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690134, content_id: 5f15cdd8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690134, content_id: "5f15cdd8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:47:43 UTC" },

      # base_path: /government/world-location-news/220338.pt, content_store: live
      # keeping id: 404426, content_id: 5f15e9f0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690150, content_id: 5f15e9f0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690150, content_id: "5f15e9f0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:47:50 UTC" },

      # base_path: /government/world-location-news/220387.ko, content_store: live
      # keeping id: 345815, content_id: 5f161096-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690159, content_id: 5f161096-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:47:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690159, content_id: "5f161096-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:47:55 UTC" },

      # base_path: /government/world-location-news/220494.es-419, content_store: live
      # keeping id: 404427, content_id: 5f163bb2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690179, content_id: 5f163bb2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690179, content_id: "5f163bb2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:48:07 UTC" },

      # base_path: /government/world-location-news/220532.pt, content_store: live
      # keeping id: 345775, content_id: 5f165c24-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690188, content_id: 5f165c24-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690188, content_id: "5f165c24-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:48:11 UTC" },

      # base_path: /government/world-location-news/220691.es-419, content_store: live
      # keeping id: 404428, content_id: 5f1847cc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690212, content_id: 5f1847cc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690212, content_id: "5f1847cc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:48:31 UTC" },

      # base_path: /government/world-location-news/220711.pt, content_store: live
      # keeping id: 285939, content_id: 5f184f66-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690215, content_id: 5f184f66-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690215, content_id: "5f184f66-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:48:33 UTC" },

      # base_path: /government/world-location-news/220750.zh-tw, content_store: live
      # keeping id: 285940, content_id: 5f185ea8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690231, content_id: 5f185ea8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:48:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690231, content_id: "5f185ea8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:48:39 UTC" },

      # base_path: /government/world-location-news/221033.pt, content_store: live
      # keeping id: 404429, content_id: 5f18fb8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690270, content_id: 5f18fb8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690270, content_id: "5f18fb8e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:49:11 UTC" },

      # base_path: /government/world-location-news/221235.zh-tw, content_store: live
      # keeping id: 404430, content_id: 5f195fc0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690303, content_id: 5f195fc0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690303, content_id: "5f195fc0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:49:34 UTC" },

      # base_path: /government/world-location-news/221237.ja, content_store: live
      # keeping id: 345816, content_id: 5f196068-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:36 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690304, content_id: 5f196068-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690304, content_id: "5f196068-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:49:35 UTC" },

      # base_path: /government/world-location-news/221408.pt, content_store: live
      # keeping id: 404431, content_id: 5f19c68b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690327, content_id: 5f19c68b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:49:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690327, content_id: "5f19c68b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:49:53 UTC" },

      # base_path: /government/world-location-news/221591.pt, content_store: live
      # keeping id: 404432, content_id: 5f1a202b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:50:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690353, content_id: 5f1a202b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:50:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690353, content_id: "5f1a202b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:50:12 UTC" },

      # base_path: /government/world-location-news/221645.zh-tw, content_store: live
      # keeping id: 345817, content_id: 5f1a3469-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:50:19 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690361, content_id: 5f1a3469-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:50:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690361, content_id: "5f1a3469-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:50:19 UTC" },

      # base_path: /government/world-location-news/221791.es-419, content_store: live
      # keeping id: 404433, content_id: 5f1a7cc5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:50:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690386, content_id: 5f1a7cc5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:50:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690386, content_id: "5f1a7cc5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:50:34 UTC" },

      # base_path: /government/world-location-news/222109.zh-tw, content_store: live
      # keeping id: 404434, content_id: 5f1b2da5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:51:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690435, content_id: 5f1b2da5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:51:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690435, content_id: "5f1b2da5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:51:06 UTC" },

      # base_path: /government/world-location-news/222285.pt, content_store: live
      # keeping id: 404435, content_id: 5f1b8b9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:51:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690458, content_id: 5f1b8b9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:51:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690458, content_id: "5f1b8b9f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:51:25 UTC" },

      # base_path: /government/world-location-news/222582.es, content_store: live
      # keeping id: 404436, content_id: 5f1c27b1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:51:58 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690514, content_id: 5f1c27b1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:51:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690514, content_id: "5f1c27b1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:51:58 UTC" },

      # base_path: /government/world-location-news/222658.es, content_store: live
      # keeping id: 345818, content_id: 5f1c466d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:52:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690526, content_id: 5f1c466d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:52:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690526, content_id: "5f1c466d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:52:06 UTC" },

      # base_path: /government/world-location-news/222697.pt, content_store: live
      # keeping id: 345819, content_id: 5f1c6b5e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:52:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690533, content_id: 5f1c6b5e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:52:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690533, content_id: "5f1c6b5e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:52:09 UTC" },

      # base_path: /government/world-location-news/222872.cs, content_store: live
      # keeping id: 690560, content_id: 5f1cbe40-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:52:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345820, content_id: 5f1cbe40-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:52:24 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345820, content_id: "5f1cbe40-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:52:24 UTC" },

      # base_path: /government/world-location-news/223229.pt, content_store: live
      # keeping id: 404437, content_id: 5f1d7371-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:53:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690608, content_id: 5f1d7371-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:53:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690608, content_id: "5f1d7371-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:53:00 UTC" },

      # base_path: /government/world-location-news/224623.es-419, content_store: live
      # keeping id: 404438, content_id: 5f204f18-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690727, content_id: 5f204f18-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690727, content_id: "5f204f18-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:55:05 UTC" },

      # base_path: /government/world-location-news/224830.es-419, content_store: live
      # keeping id: 345821, content_id: 5f20b6bc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:28 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690751, content_id: 5f20b6bc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690751, content_id: "5f20b6bc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:55:28 UTC" },

      # base_path: /government/world-location-news/224837.pt, content_store: live
      # keeping id: 285941, content_id: 5f20bc4c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690752, content_id: 5f20bc4c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690752, content_id: "5f20bc4c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:55:29 UTC" },

      # base_path: /government/world-location-news/224841.pt, content_store: live
      # keeping id: 285942, content_id: 5f20c1ca-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690754, content_id: 5f20c1ca-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690754, content_id: "5f20c1ca-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:55:29 UTC" },

      # base_path: /government/world-location-news/224845.es-419, content_store: live
      # keeping id: 345822, content_id: 5f20cab4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:30 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690755, content_id: 5f20cab4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690755, content_id: "5f20cab4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:55:30 UTC" },

      # base_path: /government/world-location-news/224941.fr, content_store: live
      # keeping id: 345823, content_id: 5f20f124-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690809, content_id: 5f20f124-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:55:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690809, content_id: "5f20f124-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:55:41 UTC" },

      # base_path: /government/world-location-news/225271.es-419, content_store: live
      # keeping id: 404439, content_id: 5f41fd5c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690850, content_id: 5f41fd5c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690850, content_id: "5f41fd5c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:56:13 UTC" },

      # base_path: /government/world-location-news/225393.sr, content_store: live
      # keeping id: 404440, content_id: 5f4233a9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690889, content_id: 5f4233a9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690889, content_id: "5f4233a9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:56:26 UTC" },

      # base_path: /government/world-location-news/225521.ko, content_store: live
      # keeping id: 404441, content_id: 5f427419-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690912, content_id: 5f427419-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690912, content_id: "5f427419-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:56:39 UTC" },

      # base_path: /government/world-location-news/225603.pt, content_store: live
      # keeping id: 404442, content_id: 5f42a50e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690922, content_id: 5f42a50e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690922, content_id: "5f42a50e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:56:48 UTC" },

      # base_path: /government/world-location-news/225635.es, content_store: live
      # keeping id: 238105, content_id: 5f42b331-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690925, content_id: 5f42b331-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690925, content_id: "5f42b331-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:56:51 UTC" },

      # base_path: /government/world-location-news/225644.es, content_store: live
      # keeping id: 345824, content_id: 5f42b5dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690926, content_id: 5f42b5dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:56:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690926, content_id: "5f42b5dc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:56:52 UTC" },

      # base_path: /government/world-location-news/225719.es-419, content_store: live
      # keeping id: 404443, content_id: 5f42e46a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690943, content_id: 5f42e46a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690943, content_id: "5f42e46a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:57:00 UTC" },

      # base_path: /government/world-location-news/225724.fr, content_store: live
      # keeping id: 404444, content_id: 5f42e624-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 690944, content_id: 5f42e624-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 690944, content_id: "5f42e624-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:57:00 UTC" },

      # base_path: /government/world-location-news/226151.es-419, content_store: live
      # keeping id: 404445, content_id: 5f43b33a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691015, content_id: 5f43b33a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691015, content_id: "5f43b33a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:57:43 UTC" },

      # base_path: /government/world-location-news/226243.pt, content_store: live
      # keeping id: 285943, content_id: 5f43ddaf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691023, content_id: 5f43ddaf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691023, content_id: "5f43ddaf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:57:49 UTC" },

      # base_path: /government/world-location-news/226260.ja, content_store: live
      # keeping id: 404446, content_id: 5f43e2b0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691026, content_id: 5f43e2b0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691026, content_id: "5f43e2b0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:57:52 UTC" },

      # base_path: /government/world-location-news/226266.es, content_store: live
      # keeping id: 404447, content_id: 5f43e607-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691028, content_id: 5f43e607-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:57:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691028, content_id: "5f43e607-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:57:53 UTC" },

      # base_path: /government/world-location-news/226373.pt, content_store: live
      # keeping id: 345825, content_id: 5f44247f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:58:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691038, content_id: 5f44247f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:58:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691038, content_id: "5f44247f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:58:04 UTC" },

      # base_path: /government/world-location-news/226541.es-419, content_store: live
      # keeping id: 345826, content_id: 5f44743d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:58:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691064, content_id: 5f44743d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:58:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691064, content_id: "5f44743d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:58:21 UTC" },

      # base_path: /government/world-location-news/226877.ja, content_store: live
      # keeping id: 345827, content_id: 5f4517ea-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:58:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691154, content_id: 5f4517ea-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 15:58:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691154, content_id: "5f4517ea-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 15:58:58 UTC" },

      # base_path: /government/world-location-news/228158.ru, content_store: live
      # keeping id: 345828, content_id: 5f47b4cc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:00:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691270, content_id: 5f47b4cc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:00:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691270, content_id: "5f47b4cc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:00:45 UTC" },

      # base_path: /government/world-location-news/228361.zh-tw, content_store: live
      # keeping id: 345830, content_id: 5f491298-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:01:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691350, content_id: 5f491298-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:01:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691350, content_id: "5f491298-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:01:05 UTC" },

      # base_path: /government/world-location-news/228522.es, content_store: live
      # keeping id: 345831, content_id: 5f4966f7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:01:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691404, content_id: 5f4966f7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:01:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691404, content_id: "5f4966f7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:01:21 UTC" },

      # base_path: /government/world-location-news/228781.lt, content_store: live
      # keeping id: 404448, content_id: 5f49e1b5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:01:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691466, content_id: 5f49e1b5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:01:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691466, content_id: "5f49e1b5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:01:50 UTC" },

      # base_path: /government/world-location-news/228905.es-419, content_store: live
      # keeping id: 404449, content_id: 5f4a24a9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691485, content_id: 5f4a24a9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691485, content_id: "5f4a24a9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:02:03 UTC" },

      # base_path: /government/world-location-news/228934.pt, content_store: live
      # keeping id: 285944, content_id: 5f4a2ef3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691488, content_id: 5f4a2ef3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691488, content_id: "5f4a2ef3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:02:06 UTC" },

      # base_path: /government/world-location-news/228956.pt, content_store: live
      # keeping id: 345832, content_id: 5f4a3ebe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691491, content_id: 5f4a3ebe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691491, content_id: "5f4a3ebe-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:02:09 UTC" },

      # base_path: /government/world-location-news/229240.es, content_store: live
      # keeping id: 285945, content_id: 5f4ac979-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691552, content_id: 5f4ac979-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691552, content_id: "5f4ac979-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:02:40 UTC" },

      # base_path: /government/world-location-news/229283.es, content_store: live
      # keeping id: 285946, content_id: 5f4aea8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691562, content_id: 5f4aea8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691562, content_id: "5f4aea8e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:02:45 UTC" },

      # base_path: /government/world-location-news/229395.zh-tw, content_store: live
      # keeping id: 345833, content_id: 5f4b2085-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691582, content_id: 5f4b2085-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:02:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691582, content_id: "5f4b2085-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:02:58 UTC" },

      # base_path: /government/world-location-news/229714.pt, content_store: live
      # keeping id: 285947, content_id: 5f4c363c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:03:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691620, content_id: 5f4c363c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:03:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691620, content_id: "5f4c363c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:03:30 UTC" },

      # base_path: /government/world-location-news/229793.es-419, content_store: draft
      # keeping id: 691632, content_id: 5f4c5333-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:03:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691631, content_id: 5f4c5333-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:03:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691631, content_id: "5f4c5333-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:03:39 UTC" },

      # base_path: /government/world-location-news/229984.es, content_store: live
      # keeping id: 404450, content_id: 5f4cc15e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:03:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691652, content_id: 5f4cc15e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:03:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691652, content_id: "5f4cc15e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:03:58 UTC" },

      # base_path: /government/world-location-news/230033.pt, content_store: live
      # keeping id: 345834, content_id: 5f4cd1db-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691668, content_id: 5f4cd1db-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691668, content_id: "5f4cd1db-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:04:03 UTC" },

      # base_path: /government/world-location-news/230354.pt, content_store: live
      # keeping id: 345835, content_id: 5f4d6f21-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691783, content_id: 5f4d6f21-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691783, content_id: "5f4d6f21-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:04:39 UTC" },

      # base_path: /government/world-location-news/230453.es-419, content_store: live
      # keeping id: 404451, content_id: 5f4db3c1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691818, content_id: 5f4db3c1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691818, content_id: "5f4db3c1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:04:49 UTC" },

      # base_path: /government/world-location-news/230454.es-419, content_store: live
      # keeping id: 404452, content_id: 5f4db46f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691819, content_id: 5f4db46f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:04:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691819, content_id: "5f4db46f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:04:49 UTC" },

      # base_path: /government/world-location-news/230569.sr, content_store: live
      # keeping id: 285948, content_id: 5f4e030c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:05:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691845, content_id: 5f4e030c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:05:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691845, content_id: "5f4e030c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:05:00 UTC" },

      # base_path: /government/world-location-news/230636.ja, content_store: live
      # keeping id: 345836, content_id: 5f4e1c8b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:05:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691859, content_id: 5f4e1c8b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:05:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691859, content_id: "5f4e1c8b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:05:07 UTC" },

      # base_path: /government/world-location-news/231029.es, content_store: live
      # keeping id: 285949, content_id: 5f4ef49d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:05:47 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691933, content_id: 5f4ef49d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:05:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691933, content_id: "5f4ef49d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:05:47 UTC" },

      # base_path: /government/world-location-news/231106.ja, content_store: draft
      # keeping id: 691953, content_id: 5f4f1808-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:05:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 691952, content_id: 5f4f1808-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:05:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 691952, content_id: "5f4f1808-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:05:54 UTC" },

      # base_path: /government/world-location-news/231480.zh-tw, content_store: live
      # keeping id: 404453, content_id: 5f4fdd0f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:06:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692028, content_id: 5f4fdd0f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:06:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692028, content_id: "5f4fdd0f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:06:33 UTC" },

      # base_path: /government/world-location-news/231664.es-419, content_store: live
      # keeping id: 404454, content_id: 5f503345-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:06:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692068, content_id: 5f503345-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:06:56 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692068, content_id: "5f503345-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:06:56 UTC" },

      # base_path: /government/world-location-news/231924.es-419, content_store: live
      # keeping id: 345837, content_id: 5f50f57b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:07:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692112, content_id: 5f50f57b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:07:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692112, content_id: "5f50f57b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:07:22 UTC" },

      # base_path: /government/world-location-news/232191.es-419, content_store: live
      # keeping id: 345838, content_id: 5f5176e5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:07:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692170, content_id: 5f5176e5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:07:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692170, content_id: "5f5176e5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:07:49 UTC" },

      # base_path: /government/world-location-news/232335.es-419, content_store: live
      # keeping id: 404455, content_id: 5f51d168-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692200, content_id: 5f51d168-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692200, content_id: "5f51d168-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:08:04 UTC" },

      # base_path: /government/world-location-news/232340.es, content_store: live
      # keeping id: 345839, content_id: 5f51d512-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692203, content_id: 5f51d512-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692203, content_id: "5f51d512-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:08:05 UTC" },

      # base_path: /government/world-location-news/232492.ja, content_store: draft
      # keeping id: 692242, content_id: 5f5221aa-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:08:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692241, content_id: 5f5221aa-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:08:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692241, content_id: "5f5221aa-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:08:21 UTC" },

      # base_path: /government/world-location-news/232492.ja, content_store: live
      # keeping id: 404456, content_id: 5f5221aa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692236, content_id: 5f5221aa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692236, content_id: "5f5221aa-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:08:20 UTC" },

      # base_path: /government/world-location-news/232577.pt, content_store: live
      # keeping id: 404457, content_id: 5f5254cd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692257, content_id: 5f5254cd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:08:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692257, content_id: "5f5254cd-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:08:28 UTC" },

      # base_path: /government/world-location-news/232909.zh-tw, content_store: live
      # keeping id: 404458, content_id: 5f53068f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:09:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692321, content_id: 5f53068f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:09:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692321, content_id: "5f53068f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:09:00 UTC" },

      # base_path: /government/world-location-news/233437.pt, content_store: live
      # keeping id: 285950, content_id: 5f543a79-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:09:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692413, content_id: 5f543a79-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:09:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692413, content_id: "5f543a79-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:09:55 UTC" },

      # base_path: /government/world-location-news/233481.az, content_store: live
      # keeping id: 692419, content_id: 5f544969-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404459, content_id: 5f544969-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404459, content_id: "5f544969-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:10:01 UTC" },

      # base_path: /government/world-location-news/233487.es-419, content_store: live
      # keeping id: 345840, content_id: 5f544b33-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692417, content_id: 5f544b33-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692417, content_id: "5f544b33-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:10:01 UTC" },

      # base_path: /government/world-location-news/233491.pt, content_store: live
      # keeping id: 404460, content_id: 5f544de6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692420, content_id: 5f544de6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:02 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692420, content_id: "5f544de6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:10:02 UTC" },

      # base_path: /government/world-location-news/233503.es, content_store: live
      # keeping id: 404461, content_id: 5f54523a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692423, content_id: 5f54523a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:10:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692423, content_id: "5f54523a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:10:04 UTC" },

      # base_path: /government/world-location-news/234925.pt, content_store: live
      # keeping id: 404462, content_id: 5f56ba6f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 692965, content_id: 5f56ba6f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:32 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 692965, content_id: "5f56ba6f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:12:32 UTC" },

      # base_path: /government/world-location-news/235129.es-419, content_store: live
      # keeping id: 404463, content_id: 5f5728f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693000, content_id: 5f5728f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693000, content_id: "5f5728f3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:12:51 UTC" },

      # base_path: /government/world-location-news/235130.es-419, content_store: live
      # keeping id: 404464, content_id: 5f57293f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693001, content_id: 5f57293f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693001, content_id: "5f57293f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:12:51 UTC" },

      # base_path: /government/world-location-news/235132.es-419, content_store: live
      # keeping id: 285951, content_id: 5f5729d9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693002, content_id: 5f5729d9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:12:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693002, content_id: "5f5729d9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:12:52 UTC" },

      # base_path: /government/world-location-news/235255.es, content_store: live
      # keeping id: 345841, content_id: 5f579f28-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693031, content_id: 5f579f28-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693031, content_id: "5f579f28-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:13:03 UTC" },

      # base_path: /government/world-location-news/235482.es, content_store: live
      # keeping id: 404465, content_id: 5f5806dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693057, content_id: 5f5806dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:24 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693057, content_id: "5f5806dc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:13:24 UTC" },

      # base_path: /government/world-location-news/235531.pt, content_store: live
      # keeping id: 345842, content_id: 5f582e20-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693063, content_id: 5f582e20-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693063, content_id: "5f582e20-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:13:29 UTC" },

      # base_path: /government/world-location-news/235744.pt, content_store: live
      # keeping id: 285952, content_id: 5f58941e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693090, content_id: 5f58941e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:13:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693090, content_id: "5f58941e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:13:50 UTC" },

      # base_path: /government/world-location-news/235864.pt, content_store: live
      # keeping id: 285953, content_id: 5f58d3ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:14:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693108, content_id: 5f58d3ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:14:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693108, content_id: "5f58d3ab-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:14:03 UTC" },

      # base_path: /government/world-location-news/235976.fr, content_store: live
      # keeping id: 404466, content_id: 5f591629-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:14:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693124, content_id: 5f591629-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:14:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693124, content_id: "5f591629-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:14:14 UTC" },

      # base_path: /government/world-location-news/236157.pt, content_store: live
      # keeping id: 404467, content_id: 5f596be0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:14:33 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693166, content_id: 5f596be0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:14:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693166, content_id: "5f596be0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:14:33 UTC" },

      # base_path: /government/world-location-news/237791.pt, content_store: live
      # keeping id: 404468, content_id: 5f5c9a71-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:17:36 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693645, content_id: 5f5c9a71-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:17:36 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693645, content_id: "5f5c9a71-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:17:36 UTC" },

      # base_path: /government/world-location-news/237892.pt, content_store: live
      # keeping id: 345843, content_id: 5f5cc990-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:17:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693669, content_id: 5f5cc990-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:17:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693669, content_id: "5f5cc990-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:17:45 UTC" },

      # base_path: /government/world-location-news/237972.es, content_store: live
      # keeping id: 285954, content_id: 5f5cf918-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:17:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693688, content_id: 5f5cf918-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:17:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693688, content_id: "5f5cf918-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:17:53 UTC" },

      # base_path: /government/world-location-news/238023.zh-tw, content_store: live
      # keeping id: 345844, content_id: 5f5d0c29-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693693, content_id: 5f5d0c29-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:17:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693693, content_id: "5f5d0c29-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:17:59 UTC" },

      # base_path: /government/world-location-news/238145.fr, content_store: live
      # keeping id: 404469, content_id: 5f5d4c90-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693708, content_id: 5f5d4c90-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693708, content_id: "5f5d4c90-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:11 UTC" },

      # base_path: /government/world-location-news/238159.es, content_store: live
      # keeping id: 404470, content_id: 5f5d51ed-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693711, content_id: 5f5d51ed-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693711, content_id: "5f5d51ed-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:13 UTC" },

      # base_path: /government/world-location-news/238160.pt, content_store: live
      # keeping id: 404471, content_id: 5f5d5239-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693710, content_id: 5f5d5239-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693710, content_id: "5f5d5239-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:13 UTC" },

      # base_path: /government/world-location-news/238161.pt, content_store: live
      # keeping id: 404472, content_id: 5f5d5286-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693712, content_id: 5f5d5286-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693712, content_id: "5f5d5286-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:13 UTC" },

      # base_path: /government/world-location-news/238189.lt, content_store: live
      # keeping id: 404473, content_id: 5f5d5ad4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693715, content_id: 5f5d5ad4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693715, content_id: "5f5d5ad4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:17 UTC" },

      # base_path: /government/world-location-news/238329.lt, content_store: live
      # keeping id: 345671, content_id: 5f5da344-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693738, content_id: 5f5da344-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693738, content_id: "5f5da344-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:31 UTC" },

      # base_path: /government/world-location-news/238420.lt, content_store: live
      # keeping id: 345684, content_id: 5f5dd9e9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693749, content_id: 5f5dd9e9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693749, content_id: "5f5dd9e9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:41 UTC" },

      # base_path: /government/world-location-news/238435.lt, content_store: live
      # keeping id: 404474, content_id: 5f5ddf49-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693752, content_id: 5f5ddf49-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693752, content_id: "5f5ddf49-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:43 UTC" },

      # base_path: /government/world-location-news/238444.sr, content_store: live
      # keeping id: 404475, content_id: 5f5de211-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693754, content_id: 5f5de211-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693754, content_id: "5f5de211-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:44 UTC" },

      # base_path: /government/world-location-news/238462.es-419, content_store: live
      # keeping id: 404476, content_id: 5f5de8ef-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693756, content_id: 5f5de8ef-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:18:46 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693756, content_id: "5f5de8ef-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:18:46 UTC" },

      # base_path: /government/world-location-news/238911.pt, content_store: live
      # keeping id: 345845, content_id: 5f5ed86e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693824, content_id: 5f5ed86e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693824, content_id: "5f5ed86e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:19:34 UTC" },

      # base_path: /government/world-location-news/238912.pt, content_store: live
      # keeping id: 404477, content_id: 5f5ed8e6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693825, content_id: 5f5ed8e6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693825, content_id: "5f5ed8e6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:19:34 UTC" },

      # base_path: /government/world-location-news/238913.pt, content_store: live
      # keeping id: 404478, content_id: 5f5edb1d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693826, content_id: 5f5edb1d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693826, content_id: "5f5edb1d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:19:34 UTC" },

      # base_path: /government/world-location-news/238916.pt, content_store: live
      # keeping id: 285955, content_id: 5f5edfc0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693827, content_id: 5f5edfc0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693827, content_id: "5f5edfc0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:19:35 UTC" },

      # base_path: /government/world-location-news/238921.pt, content_store: live
      # keeping id: 404479, content_id: 5f5ee65e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693828, content_id: 5f5ee65e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693828, content_id: "5f5ee65e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:19:35 UTC" },

      # base_path: /government/world-location-news/239068.pt, content_store: live
      # keeping id: 404480, content_id: 5f5f326f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 693849, content_id: 5f5f326f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:19:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 693849, content_id: "5f5f326f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:19:49 UTC" },

      # base_path: /government/world-location-news/239306.cs, content_store: live
      # keeping id: 693906, content_id: 5f5f9ca4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345846, content_id: 5f5f9ca4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345846, content_id: "5f5f9ca4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:20:13 UTC" },

      # base_path: /government/world-location-news/239810.es-419, content_store: live
      # keeping id: 345847, content_id: 5f60d7ed-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694268, content_id: 5f60d7ed-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694268, content_id: "5f60d7ed-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:20:43 UTC" },

      # base_path: /government/world-location-news/239826.es-419, content_store: live
      # keeping id: 285956, content_id: 5f60de76-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694275, content_id: 5f60de76-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694275, content_id: "5f60de76-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:20:45 UTC" },

      # base_path: /government/world-location-news/239845.lt, content_store: live
      # keeping id: 285957, content_id: 5f60e413-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:47 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694280, content_id: 5f60e413-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694280, content_id: "5f60e413-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:20:47 UTC" },

      # base_path: /government/world-location-news/239922.el, content_store: live
      # keeping id: 694297, content_id: 5f6114c1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404481, content_id: 5f6114c1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:20:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404481, content_id: "5f6114c1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:20:54 UTC" },

      # base_path: /government/world-location-news/240063.zh-tw, content_store: live
      # keeping id: 285959, content_id: 5f615adb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694323, content_id: 5f615adb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694323, content_id: "5f615adb-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:21:08 UTC" },

      # base_path: /government/world-location-news/240207.pt, content_store: live
      # keeping id: 345848, content_id: 5f61a449-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694341, content_id: 5f61a449-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694341, content_id: "5f61a449-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:21:22 UTC" },

      # base_path: /government/world-location-news/240208.pt, content_store: live
      # keeping id: 345849, content_id: 5f61a492-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694338, content_id: 5f61a492-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694338, content_id: "5f61a492-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:21:22 UTC" },

      # base_path: /government/world-location-news/240209.pt, content_store: live
      # keeping id: 345850, content_id: 5f61a4de-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694339, content_id: 5f61a4de-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694339, content_id: "5f61a4de-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:21:22 UTC" },

      # base_path: /government/world-location-news/240210.pt, content_store: live
      # keeping id: 285960, content_id: 5f61a529-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694342, content_id: 5f61a529-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694342, content_id: "5f61a529-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:21:22 UTC" },

      # base_path: /government/world-location-news/240427.es-419, content_store: live
      # keeping id: 285961, content_id: 5f62064f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694386, content_id: 5f62064f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694386, content_id: "5f62064f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:21:42 UTC" },

      # base_path: /government/world-location-news/240429.pt, content_store: live
      # keeping id: 285962, content_id: 5f6206e5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694387, content_id: 5f6206e5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:21:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694387, content_id: "5f6206e5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:21:43 UTC" },

      # base_path: /government/world-location-news/240607.es-419, content_store: live
      # keeping id: 345851, content_id: 5f6268e3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:22:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694425, content_id: 5f6268e3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:22:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694425, content_id: "5f6268e3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:22:01 UTC" },

      # base_path: /government/world-location-news/240657.ja, content_store: live
      # keeping id: 404485, content_id: 5f628deb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:22:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694433, content_id: 5f628deb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:22:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694433, content_id: "5f628deb-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:22:06 UTC" },

      # base_path: /government/world-location-news/240897.es-419, content_store: live
      # keeping id: 345852, content_id: 5f62f6ce-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:22:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694474, content_id: 5f62f6ce-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:22:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694474, content_id: "5f62f6ce-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:22:37 UTC" },

      # base_path: /government/world-location-news/241312.de, content_store: live
      # keeping id: 694555, content_id: 5f63cd30-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345853, content_id: 5f63cd30-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345853, content_id: "5f63cd30-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:23:20 UTC" },

      # base_path: /government/world-location-news/241353.cs, content_store: live
      # keeping id: 694567, content_id: 5f63e686-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285963, content_id: 5f63e686-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:24 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285963, content_id: "5f63e686-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:23:24 UTC" },

      # base_path: /government/world-location-news/241398.pt, content_store: live
      # keeping id: 285964, content_id: 5f6400fa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694571, content_id: 5f6400fa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694571, content_id: "5f6400fa-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:23:30 UTC" },

      # base_path: /government/world-location-news/241585.es, content_store: live
      # keeping id: 404486, content_id: 5f643f4a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694592, content_id: 5f643f4a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:23:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694592, content_id: "5f643f4a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:23:43 UTC" },

      # base_path: /government/world-location-news/241804.es-419, content_store: draft
      # keeping id: 694652, content_id: 5f64a3fd-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:24:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694650, content_id: 5f64a3fd-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:24:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694650, content_id: "5f64a3fd-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:24:05 UTC" },

      # base_path: /government/world-location-news/241850.es-419, content_store: live
      # keeping id: 345854, content_id: 5f64b37e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694661, content_id: 5f64b37e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694661, content_id: "5f64b37e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:24:10 UTC" },

      # base_path: /government/world-location-news/241853.es-419, content_store: live
      # keeping id: 404487, content_id: 5f64b476-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694662, content_id: 5f64b476-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694662, content_id: "5f64b476-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:24:10 UTC" },

      # base_path: /government/world-location-news/241859.ja, content_store: live
      # keeping id: 404488, content_id: 5f64b9b5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694663, content_id: 5f64b9b5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694663, content_id: "5f64b9b5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:24:12 UTC" },

      # base_path: /government/world-location-news/242212.el, content_store: live
      # keeping id: 694746, content_id: 5f65b514-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 238106, content_id: 5f65b514-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:46 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 238106, content_id: "5f65b514-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:24:46 UTC" },

      # base_path: /government/world-location-news/242214.lt, content_store: live
      # keeping id: 345855, content_id: 5f65b5af-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:47 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694745, content_id: 5f65b5af-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694745, content_id: "5f65b5af-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:24:47 UTC" },

      # base_path: /government/world-location-news/242260.pt, content_store: live
      # keeping id: 404489, content_id: 5f65c797-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694757, content_id: 5f65c797-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:24:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694757, content_id: "5f65c797-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:24:52 UTC" },

      # base_path: /government/world-location-news/242623.pt, content_store: live
      # keeping id: 345856, content_id: 5f668f1e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:25:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694848, content_id: 5f668f1e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:25:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694848, content_id: "5f668f1e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:25:29 UTC" },

      # base_path: /government/world-location-news/242722.pt, content_store: live
      # keeping id: 345857, content_id: 5f66b478-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:25:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694856, content_id: 5f66b478-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:25:36 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694856, content_id: "5f66b478-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:25:36 UTC" },

      # base_path: /government/world-location-news/242763.es-419, content_store: draft
      # keeping id: 694863, content_id: 5f66d725-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:25:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694862, content_id: 5f66d725-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:25:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694862, content_id: "5f66d725-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:25:39 UTC" },

      # base_path: /government/world-location-news/242775.es, content_store: live
      # keeping id: 285965, content_id: 5f66ded8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:25:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694865, content_id: 5f66ded8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:25:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694865, content_id: "5f66ded8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:25:41 UTC" },

      # base_path: /government/world-location-news/242996.pt, content_store: live
      # keeping id: 285966, content_id: 5f674597-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:26:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694914, content_id: 5f674597-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:26:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694914, content_id: "5f674597-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:26:00 UTC" },

      # base_path: /government/world-location-news/243006.pt, content_store: live
      # keeping id: 345858, content_id: 5f6748a6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:26:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 694915, content_id: 5f6748a6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:26:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 694915, content_id: "5f6748a6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:26:01 UTC" },

      # base_path: /government/world-location-news/243962.es-419, content_store: live
      # keeping id: 404490, content_id: 5f8f6022-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:27:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695127, content_id: 5f8f6022-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:27:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695127, content_id: "5f8f6022-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:27:38 UTC" },

      # base_path: /government/world-location-news/244351.pt, content_store: live
      # keeping id: 404491, content_id: 5f9c6902-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:28:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695187, content_id: 5f9c6902-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:28:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695187, content_id: "5f9c6902-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:28:16 UTC" },

      # base_path: /government/world-location-news/245635.zh-tw, content_store: live
      # keeping id: 404405, content_id: 5fa5c4fc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:30:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695389, content_id: 5fa5c4fc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:30:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695389, content_id: "5fa5c4fc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:30:05 UTC" },

      # base_path: /government/world-location-news/245735.de, content_store: live
      # keeping id: 695409, content_id: 5fa5f730-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:30:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404492, content_id: 5fa5f730-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:30:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404492, content_id: "5fa5f730-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:30:16 UTC" },

      # base_path: /government/world-location-news/246128.pt, content_store: live
      # keeping id: 404493, content_id: 5fa6a5d1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:30:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695458, content_id: 5fa6a5d1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:30:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695458, content_id: "5fa6a5d1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:30:41 UTC" },

      # base_path: /government/world-location-news/246593.lt, content_store: live
      # keeping id: 285967, content_id: 5fa794d3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:31:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695529, content_id: 5fa794d3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:31:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695529, content_id: "5fa794d3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:31:25 UTC" },

      # base_path: /government/world-location-news/246679.es-419, content_store: live
      # keeping id: 404494, content_id: 5fa7c20f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:31:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695539, content_id: 5fa7c20f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:31:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695539, content_id: "5fa7c20f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:31:33 UTC" },

      # base_path: /government/world-location-news/246875.es-419, content_store: live
      # keeping id: 345859, content_id: 5fa8359f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:31:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695584, content_id: 5fa8359f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:31:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695584, content_id: "5fa8359f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:31:52 UTC" },

      # base_path: /government/world-location-news/247263.zh, content_store: live
      # keeping id: 285968, content_id: 5fa8d5fe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:32:30 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695624, content_id: 5fa8d5fe-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:32:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695624, content_id: "5fa8d5fe-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:32:30 UTC" },

      # base_path: /government/world-location-news/247572.es-419, content_store: live
      # keeping id: 285969, content_id: 5fa97d56-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695676, content_id: 5fa97d56-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695676, content_id: "5fa97d56-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:33:11 UTC" },

      # base_path: /government/world-location-news/247580.ja, content_store: live
      # keeping id: 345860, content_id: 5fa98033-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695677, content_id: 5fa98033-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695677, content_id: "5fa98033-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:33:11 UTC" },

      # base_path: /government/world-location-news/247699.lt, content_store: live
      # keeping id: 285970, content_id: 5fa9c08d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:24 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695701, content_id: 5fa9c08d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:23 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695701, content_id: "5fa9c08d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:33:23 UTC" },

      # base_path: /government/world-location-news/247706.es, content_store: live
      # keeping id: 404495, content_id: 5fa9c4f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:24 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695704, content_id: 5fa9c4f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:24 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695704, content_id: "5fa9c4f3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:33:24 UTC" },

      # base_path: /government/world-location-news/247944.it, content_store: live
      # keeping id: 345861, content_id: 5faa47e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695744, content_id: 5faa47e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:33:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695744, content_id: "5faa47e2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:33:50 UTC" },

      # base_path: /government/world-location-news/248692.ko, content_store: live
      # keeping id: 404496, content_id: 5fd8ac94-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:35:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695756, content_id: 5fd8ac94-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:35:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695756, content_id: "5fd8ac94-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:35:10 UTC" },

      # base_path: /government/world-location-news/249069.pt, content_store: live
      # keeping id: 345862, content_id: 5fd93dc2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:35:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695792, content_id: 5fd93dc2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:35:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695792, content_id: "5fd93dc2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:35:31 UTC" },

      # base_path: /government/world-location-news/249089.zh-tw, content_store: live
      # keeping id: 404497, content_id: 5fd955e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:35:33 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695797, content_id: 5fd955e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:35:33 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695797, content_id: "5fd955e2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:35:33 UTC" },

      # base_path: /government/world-location-news/250979.zh-tw, content_store: draft
      # keeping id: 695889, content_id: 5fdca35b-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:36:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695888, content_id: 5fdca35b-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:36:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695888, content_id: "5fdca35b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:36:48 UTC" },

      # base_path: /government/world-location-news/250984.zh-tw, content_store: live
      # keeping id: 404499, content_id: 5fdca4dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:36:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695890, content_id: 5fdca4dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:36:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695890, content_id: "5fdca4dc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:36:49 UTC" },

      # base_path: /government/world-location-news/251432.fr, content_store: live
      # keeping id: 404500, content_id: 5fdd8927-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:37:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695932, content_id: 5fdd8927-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:37:23 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695932, content_id: "5fdd8927-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:37:23 UTC" },

      # base_path: /government/world-location-news/251447.zh-tw, content_store: live
      # keeping id: 404501, content_id: 5fdd9871-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:37:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695933, content_id: 5fdd9871-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:37:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695933, content_id: "5fdd9871-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:37:25 UTC" },

      # base_path: /government/world-location-news/251691.pt, content_store: live
      # keeping id: 285972, content_id: 5fde1270-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:37:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 695971, content_id: 5fde1270-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:37:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 695971, content_id: "5fde1270-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:37:49 UTC" },

      # base_path: /government/world-location-news/252071.es-419, content_store: live
      # keeping id: 345863, content_id: 5fe14021-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:38:28 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696023, content_id: 5fe14021-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:38:27 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696023, content_id: "5fe14021-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:38:27 UTC" },

      # base_path: /government/world-location-news/252203.pt, content_store: live
      # keeping id: 404502, content_id: 5fe184d3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:38:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696052, content_id: 5fe184d3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:38:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696052, content_id: "5fe184d3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:38:41 UTC" },

      # base_path: /government/world-location-news/252564.es-419, content_store: draft
      # keeping id: 696110, content_id: 5fe2444a-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:39:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696108, content_id: 5fe2444a-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:39:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696108, content_id: "5fe2444a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:39:14 UTC" },

      # base_path: /government/world-location-news/252564.es-419, content_store: live
      # keeping id: 345864, content_id: 5fe2444a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696104, content_id: 5fe2444a-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696104, content_id: "5fe2444a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:39:13 UTC" },

      # base_path: /government/world-location-news/252606.zh-tw, content_store: live
      # keeping id: 285973, content_id: 5fe254d1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696117, content_id: 5fe254d1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:18 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696117, content_id: "5fe254d1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:39:18 UTC" },

      # base_path: /government/world-location-news/252778.zh-tw, content_store: live
      # keeping id: 285974, content_id: 5fe2a59e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696145, content_id: 5fe2a59e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696145, content_id: "5fe2a59e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:39:35 UTC" },

      # base_path: /government/world-location-news/252816.fr, content_store: draft
      # keeping id: 696159, content_id: 5fe2bab5-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:39:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696158, content_id: 5fe2bab5-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:39:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696158, content_id: "5fe2bab5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:39:40 UTC" },

      # base_path: /government/world-location-news/252816.fr, content_store: live
      # keeping id: 345865, content_id: 5fe2bab5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696155, content_id: 5fe2bab5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:39:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696155, content_id: "5fe2bab5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:39:39 UTC" },

      # base_path: /government/world-location-news/252842.ar, content_store: draft
      # keeping id: 696163, content_id: 5fe2d38d-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:39:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696162, content_id: 5fe2d38d-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:39:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696162, content_id: "5fe2d38d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:39:42 UTC" },

      # base_path: /government/world-location-news/253081.pt, content_store: live
      # keeping id: 345866, content_id: 5fe35227-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696186, content_id: 5fe35227-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696186, content_id: "5fe35227-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:40:05 UTC" },

      # base_path: /government/world-location-news/253083.pt, content_store: live
      # keeping id: 404503, content_id: 5fe352c6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696188, content_id: 5fe352c6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696188, content_id: "5fe352c6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:40:05 UTC" },

      # base_path: /government/world-location-news/253263.es-419, content_store: live
      # keeping id: 345867, content_id: 5fe3a795-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696221, content_id: 5fe3a795-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:24 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696221, content_id: "5fe3a795-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:40:24 UTC" },

      # base_path: /government/world-location-news/253325.pt, content_store: live
      # keeping id: 345868, content_id: 5fe3c2f5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696246, content_id: 5fe3c2f5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:32 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696246, content_id: "5fe3c2f5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:40:32 UTC" },

      # base_path: /government/world-location-news/253328.es, content_store: live
      # keeping id: 285975, content_id: 5fe3c5ef-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:33 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696249, content_id: 5fe3c5ef-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:32 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696249, content_id: "5fe3c5ef-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:40:32 UTC" },

      # base_path: /government/world-location-news/253410.es-419, content_store: live
      # keeping id: 404504, content_id: 5fe3f0b3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696269, content_id: 5fe3f0b3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696269, content_id: "5fe3f0b3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:40:41 UTC" },

      # base_path: /government/world-location-news/253585.pt, content_store: live
      # keeping id: 285976, content_id: 5fe4c666-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696298, content_id: 5fe4c666-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:40:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696298, content_id: "5fe4c666-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:40:57 UTC" },

      # base_path: /government/world-location-news/253913.es-419, content_store: live
      # keeping id: 404505, content_id: 5fe5757f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:41:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696349, content_id: 5fe5757f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:41:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696349, content_id: "5fe5757f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:41:29 UTC" },

      # base_path: /government/world-location-news/254154.zh-tw, content_store: live
      # keeping id: 285977, content_id: 5fe5e83d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:41:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696397, content_id: 5fe5e83d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:41:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696397, content_id: "5fe5e83d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:41:52 UTC" },

      # base_path: /government/world-location-news/254304.es-419, content_store: draft
      # keeping id: 696439, content_id: 5fe63517-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:42:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696438, content_id: 5fe63517-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:42:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696438, content_id: "5fe63517-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:42:07 UTC" },

      # base_path: /government/world-location-news/254304.es-419, content_store: live
      # keeping id: 404507, content_id: 5fe63517-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696436, content_id: 5fe63517-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696436, content_id: "5fe63517-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:42:06 UTC" },

      # base_path: /government/world-location-news/254396.pt, content_store: live
      # keeping id: 285978, content_id: 5fe66b42-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696457, content_id: 5fe66b42-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696457, content_id: "5fe66b42-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:42:15 UTC" },

      # base_path: /government/world-location-news/254431.es-419, content_store: live
      # keeping id: 404508, content_id: 5fe677ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696464, content_id: 5fe677ab-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696464, content_id: "5fe677ab-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:42:19 UTC" },

      # base_path: /government/world-location-news/254530.es, content_store: draft
      # keeping id: 696486, content_id: 5fe6a8be-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:42:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696485, content_id: 5fe6a8be-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:42:27 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696485, content_id: "5fe6a8be-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:42:27 UTC" },

      # base_path: /government/world-location-news/254970.pt, content_store: live
      # keeping id: 404509, content_id: 5fe76eaa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696705, content_id: 5fe76eaa-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:42:56 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696705, content_id: "5fe76eaa-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:42:56 UTC" },

      # base_path: /government/world-location-news/255470.es-419, content_store: live
      # keeping id: 404510, content_id: 5fe86b49-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696748, content_id: 5fe86b49-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696748, content_id: "5fe86b49-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:43:34 UTC" },

      # base_path: /government/world-location-news/255564.lt, content_store: live
      # keeping id: 404511, content_id: 5fe8a216-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696775, content_id: 5fe8a216-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696775, content_id: "5fe8a216-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:43:43 UTC" },

      # base_path: /government/world-location-news/255672.pt, content_store: live
      # keeping id: 345869, content_id: 5fe8cf32-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696796, content_id: 5fe8cf32-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696796, content_id: "5fe8cf32-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:43:52 UTC" },

      # base_path: /government/world-location-news/255674.es-419, content_store: live
      # keeping id: 345870, content_id: 5fe8d1c4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696797, content_id: 5fe8d1c4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696797, content_id: "5fe8d1c4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:43:53 UTC" },

      # base_path: /government/world-location-news/255719.es, content_store: live
      # keeping id: 404512, content_id: 5fe8ef23-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:58 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696807, content_id: 5fe8ef23-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696807, content_id: "5fe8ef23-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:43:57 UTC" },

      # base_path: /government/world-location-news/255741.es, content_store: live
      # keeping id: 285979, content_id: 5fe8fa0e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:44:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696814, content_id: 5fe8fa0e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:43:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696814, content_id: "5fe8fa0e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:43:59 UTC" },

      # base_path: /government/world-location-news/256627.es, content_store: live
      # keeping id: 285980, content_id: 5fea9641-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:45:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 696969, content_id: 5fea9641-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:45:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 696969, content_id: "5fea9641-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:45:25 UTC" },

      # base_path: /government/world-location-news/256826.pt, content_store: live
      # keeping id: 404513, content_id: 5feafa01-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:45:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697011, content_id: 5feafa01-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:45:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697011, content_id: "5feafa01-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:45:48 UTC" },

      # base_path: /government/world-location-news/256970.zh-tw, content_store: live
      # keeping id: 404514, content_id: 5feb4139-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697048, content_id: 5feb4139-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697048, content_id: "5feb4139-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:46:04 UTC" },

      # base_path: /government/world-location-news/257123.el, content_store: live
      # keeping id: 697081, content_id: 5feb9778-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285981, content_id: 5feb9778-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285981, content_id: "5feb9778-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:46:19 UTC" },

      # base_path: /government/world-location-news/257296.pt, content_store: live
      # keeping id: 404515, content_id: 5febf333-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697127, content_id: 5febf333-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697127, content_id: "5febf333-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:46:37 UTC" },

      # base_path: /government/world-location-news/257368.es-419, content_store: live
      # keeping id: 404516, content_id: 5fec0e9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697159, content_id: 5fec0e9f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697159, content_id: "5fec0e9f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:46:45 UTC" },

      # base_path: /government/world-location-news/257415.pt, content_store: live
      # keeping id: 345871, content_id: 5fec2dec-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697188, content_id: 5fec2dec-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697188, content_id: "5fec2dec-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:46:50 UTC" },

      # base_path: /government/world-location-news/257425.ja, content_store: live
      # keeping id: 345872, content_id: 5fec38a3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697191, content_id: 5fec38a3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:46:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697191, content_id: "5fec38a3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:46:52 UTC" },

      # base_path: /government/world-location-news/257525.ar, content_store: live
      # keeping id: 697216, content_id: 5fec5a27-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:47:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345873, content_id: 5fec5a27-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:47:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345873, content_id: "5fec5a27-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:47:03 UTC" },

      # base_path: /government/world-location-news/257608.es-419, content_store: draft
      # keeping id: 697233, content_id: 5fec88c6-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:47:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697232, content_id: 5fec88c6-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:47:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697232, content_id: "5fec88c6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:47:11 UTC" },

      # base_path: /government/world-location-news/258126.el, content_store: live
      # keeping id: 697322, content_id: 5fed9b56-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:48:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345874, content_id: 5fed9b56-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:48:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345874, content_id: "5fed9b56-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:48:06 UTC" },

      # base_path: /government/world-location-news/259213.pt, content_store: live
      # keeping id: 404517, content_id: 5fefb92b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:49:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697498, content_id: 5fefb92b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:49:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697498, content_id: "5fefb92b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:49:57 UTC" },

      # base_path: /government/world-location-news/259217.pt, content_store: live
      # keeping id: 345875, content_id: 5fefba88-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:49:58 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697499, content_id: 5fefba88-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:49:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697499, content_id: "5fefba88-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:49:57 UTC" },

      # base_path: /government/world-location-news/259309.bg, content_store: live
      # keeping id: 697518, content_id: 5feff450-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:50:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404518, content_id: 5feff450-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:50:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404518, content_id: "5feff450-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:50:07 UTC" },

      # base_path: /government/world-location-news/259782.ja, content_store: live
      # keeping id: 404519, content_id: 5ff0e456-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:50:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697588, content_id: 5ff0e456-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:50:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697588, content_id: "5ff0e456-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:50:52 UTC" },

      # base_path: /government/world-location-news/259846.es, content_store: draft
      # keeping id: 697606, content_id: 5ff11087-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:50:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697605, content_id: 5ff11087-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:50:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697605, content_id: "5ff11087-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:50:58 UTC" },

      # base_path: /government/world-location-news/260204.pt, content_store: live
      # keeping id: 404520, content_id: 5ff1c72d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697736, content_id: 5ff1c72d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697736, content_id: "5ff1c72d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:51:41 UTC" },

      # base_path: /government/world-location-news/260245.es, content_store: live
      # keeping id: 404521, content_id: 5ff1d61e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697746, content_id: 5ff1d61e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:46 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697746, content_id: "5ff1d61e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:51:46 UTC" },

      # base_path: /government/world-location-news/260250.fr, content_store: live
      # keeping id: 285982, content_id: 5ff1d7a9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697748, content_id: 5ff1d7a9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:46 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697748, content_id: "5ff1d7a9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:51:46 UTC" },

      # base_path: /government/world-location-news/260295.el, content_store: live
      # keeping id: 697759, content_id: 601a52f2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285983, content_id: 601a52f2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:51:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285983, content_id: "601a52f2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:51:50 UTC" },

      # base_path: /government/world-location-news/260560.pt, content_store: live
      # keeping id: 285984, content_id: 601acffb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697815, content_id: 601acffb-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697815, content_id: "601acffb-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:15 UTC" },

      # base_path: /government/world-location-news/260563.pt, content_store: live
      # keeping id: 345876, content_id: 601ad3f5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697816, content_id: 601ad3f5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697816, content_id: "601ad3f5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:15 UTC" },

      # base_path: /government/world-location-news/260600.cs, content_store: live
      # keeping id: 697823, content_id: 601aef00-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404506, content_id: 601aef00-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404506, content_id: "601aef00-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:19 UTC" },

      # base_path: /government/world-location-news/260857.pt, content_store: draft
      # keeping id: 697864, content_id: 601b6ca3-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:52:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697863, content_id: 601b6ca3-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:52:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697863, content_id: "601b6ca3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:44 UTC" },

      # base_path: /government/world-location-news/260920.es-419, content_store: live
      # keeping id: 285985, content_id: 601b95ec-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697880, content_id: 601b95ec-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697880, content_id: "601b95ec-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:50 UTC" },

      # base_path: /government/world-location-news/260940.es-419, content_store: live
      # keeping id: 404522, content_id: 601ba0f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697886, content_id: 601ba0f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697886, content_id: "601ba0f3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:51 UTC" },

      # base_path: /government/world-location-news/260942.pt, content_store: draft
      # keeping id: 697889, content_id: 601ba18e-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:52:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697887, content_id: 601ba18e-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:52:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697887, content_id: "601ba18e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:52 UTC" },

      # base_path: /government/world-location-news/260960.zh-tw, content_store: live
      # keeping id: 345877, content_id: 601ba6f0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697891, content_id: 601ba6f0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697891, content_id: "601ba6f0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:54 UTC" },

      # base_path: /government/world-location-news/260995.cs, content_store: live
      # keeping id: 697903, content_id: 601bb381-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 285986, content_id: 601bb381-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:52:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 285986, content_id: "601bb381-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:52:58 UTC" },

      # base_path: /government/world-location-news/261172.ja, content_store: live
      # keeping id: 345878, content_id: 601c1dc0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697930, content_id: 601c1dc0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697930, content_id: "601c1dc0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:53:15 UTC" },

      # base_path: /government/world-location-news/261384.pt, content_store: draft
      # keeping id: 697965, content_id: 601c833a-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:53:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697964, content_id: 601c833a-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:53:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697964, content_id: "601c833a-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:53:35 UTC" },

      # base_path: /government/world-location-news/261385.pt, content_store: live
      # keeping id: 285987, content_id: 601c838b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697963, content_id: 601c838b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697963, content_id: "601c838b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:53:35 UTC" },

      # base_path: /government/world-location-news/261513.de, content_store: live
      # keeping id: 697988, content_id: 601cc60f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404523, content_id: 601cc60f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404523, content_id: "601cc60f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:53:48 UTC" },

      # base_path: /government/world-location-news/261564.el, content_store: live
      # keeping id: 697995, content_id: 601ce4e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 238107, content_id: 601ce4e2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 238107, content_id: "601ce4e2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:53:53 UTC" },

      # base_path: /government/world-location-news/261575.pt, content_store: live
      # keeping id: 285988, content_id: 601cf510-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697997, content_id: 601cf510-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697997, content_id: "601cf510-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:53:54 UTC" },

      # base_path: /government/world-location-news/261585.ja, content_store: live
      # keeping id: 345879, content_id: 601cf82d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 697999, content_id: 601cf82d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:53:56 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 697999, content_id: "601cf82d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:53:56 UTC" },

      # base_path: /government/world-location-news/261720.pt, content_store: live
      # keeping id: 345880, content_id: 601d3f72-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698020, content_id: 601d3f72-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698020, content_id: "601d3f72-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:10 UTC" },

      # base_path: /government/world-location-news/261754.es-419, content_store: live
      # keeping id: 345881, content_id: 601d4abd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698029, content_id: 601d4abd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698029, content_id: "601d4abd-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:14 UTC" },

      # base_path: /government/world-location-news/261846.pt, content_store: live
      # keeping id: 345882, content_id: 601d7734-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:24 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698042, content_id: 601d7734-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:23 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698042, content_id: "601d7734-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:23 UTC" },

      # base_path: /government/world-location-news/261897.es-419, content_store: live
      # keeping id: 345883, content_id: 601ecba1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698051, content_id: 601ecba1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698051, content_id: "601ecba1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:28 UTC" },

      # base_path: /government/world-location-news/261960.es-419, content_store: live
      # keeping id: 404524, content_id: 601ee865-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698066, content_id: 601ee865-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698066, content_id: "601ee865-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:34 UTC" },

      # base_path: /government/world-location-news/261976.es, content_store: live
      # keeping id: 345884, content_id: 601ef282-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698067, content_id: 601ef282-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:36 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698067, content_id: "601ef282-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:36 UTC" },

      # base_path: /government/world-location-news/262113.zh-tw, content_store: draft
      # keeping id: 698093, content_id: 601f3707-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:54:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698092, content_id: 601f3707-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:54:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698092, content_id: "601f3707-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:50 UTC" },

      # base_path: /government/world-location-news/262114.zh-tw, content_store: live
      # keeping id: 404525, content_id: 601f3757-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698091, content_id: 601f3757-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:54:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698091, content_id: "601f3757-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:54:50 UTC" },

      # base_path: /government/world-location-news/262678.pt, content_store: live
      # keeping id: 345885, content_id: 60206d26-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698184, content_id: 60206d26-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698184, content_id: "60206d26-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:55:49 UTC" },

      # base_path: /government/world-location-news/262681.pt, content_store: live
      # keeping id: 404526, content_id: 60206e10-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698187, content_id: 60206e10-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698187, content_id: "60206e10-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:55:49 UTC" },

      # base_path: /government/world-location-news/262717.uk, content_store: live
      # keeping id: 404527, content_id: 602092b8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698190, content_id: 602092b8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698190, content_id: "602092b8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:55:53 UTC" },

      # base_path: /government/world-location-news/262765.es, content_store: live
      # keeping id: 404528, content_id: 6020a504-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698202, content_id: 6020a504-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:55:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698202, content_id: "6020a504-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:55:58 UTC" },

      # base_path: /government/world-location-news/262799.es-419, content_store: live
      # keeping id: 285989, content_id: 6020b22e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698211, content_id: 6020b22e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:02 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698211, content_id: "6020b22e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:02 UTC" },

      # base_path: /government/world-location-news/262824.es-419, content_store: live
      # keeping id: 345886, content_id: 6020bb94-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698221, content_id: 6020bb94-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698221, content_id: "6020bb94-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:05 UTC" },

      # base_path: /government/world-location-news/263027.es-419, content_store: live
      # keeping id: 345887, content_id: 60212ef1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698262, content_id: 60212ef1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698262, content_id: "60212ef1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:26 UTC" },

      # base_path: /government/world-location-news/263028.pt, content_store: draft
      # keeping id: 698265, content_id: 60212f3c-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:56:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698264, content_id: 60212f3c-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:56:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698264, content_id: "60212f3c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:25 UTC" },

      # base_path: /government/world-location-news/263029.pt, content_store: live
      # keeping id: 404529, content_id: 60212f88-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698263, content_id: 60212f88-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698263, content_id: "60212f88-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:26 UTC" },

      # base_path: /government/world-location-news/263031.es-419, content_store: live
      # keeping id: 345888, content_id: 6021301e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698266, content_id: 6021301e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698266, content_id: "6021301e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:26 UTC" },

      # base_path: /government/world-location-news/263032.ja, content_store: live
      # keeping id: 238108, content_id: 6021306b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698267, content_id: 6021306b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698267, content_id: "6021306b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:26 UTC" },

      # base_path: /government/world-location-news/263173.es-419, content_store: live
      # keeping id: 345889, content_id: 60217578-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698296, content_id: 60217578-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:56:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698296, content_id: "60217578-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:56:42 UTC" },

      # base_path: /government/world-location-news/263387.zh-tw, content_store: draft
      # keeping id: 698340, content_id: 6021d779-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:57:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698339, content_id: 6021d779-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:57:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698339, content_id: "6021d779-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:57:05 UTC" },

      # base_path: /government/world-location-news/263388.zh-tw, content_store: live
      # keeping id: 404530, content_id: 6021d7c6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698338, content_id: 6021d7c6-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698338, content_id: "6021d7c6-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:57:05 UTC" },

      # base_path: /government/world-location-news/263630.pt, content_store: live
      # keeping id: 345890, content_id: 60225a52-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698383, content_id: 60225a52-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698383, content_id: "60225a52-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:57:31 UTC" },

      # base_path: /government/world-location-news/263748.es-419, content_store: live
      # keeping id: 285990, content_id: 60229a8b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698403, content_id: 60229a8b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698403, content_id: "60229a8b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:57:43 UTC" },

      # base_path: /government/world-location-news/263762.it, content_store: live
      # keeping id: 345891, content_id: 60229fd1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698405, content_id: 60229fd1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698405, content_id: "60229fd1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:57:45 UTC" },

      # base_path: /government/world-location-news/263764.de, content_store: live
      # keeping id: 698406, content_id: 6022a07c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:46 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345892, content_id: 6022a07c-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345892, content_id: "6022a07c-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:57:45 UTC" },

      # base_path: /government/world-location-news/263836.es-419, content_store: live
      # keeping id: 345893, content_id: 6022ba28-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698415, content_id: 6022ba28-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:57:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698415, content_id: "6022ba28-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:57:51 UTC" },

      # base_path: /government/world-location-news/264303.es, content_store: draft
      # keeping id: 698499, content_id: 6023aac0-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:58:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698498, content_id: 6023aac0-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 16:58:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698498, content_id: "6023aac0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:58:40 UTC" },

      # base_path: /government/world-location-news/264303.es, content_store: live
      # keeping id: 404531, content_id: 6023aac0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:58:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698496, content_id: 6023aac0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:58:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698496, content_id: "6023aac0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:58:39 UTC" },

      # base_path: /government/world-location-news/264315.pt, content_store: live
      # keeping id: 404532, content_id: 6023bd09-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:58:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698497, content_id: 6023bd09-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:58:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698497, content_id: "6023bd09-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:58:40 UTC" },

      # base_path: /government/world-location-news/264569.es-419, content_store: live
      # keeping id: 285991, content_id: 60243394-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:59:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698524, content_id: 60243394-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:59:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698524, content_id: "60243394-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:59:06 UTC" },

      # base_path: /government/world-location-news/264597.zh-tw, content_store: live
      # keeping id: 345894, content_id: 60244d0e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:59:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698528, content_id: 60244d0e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:59:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698528, content_id: "60244d0e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:59:08 UTC" },

      # base_path: /government/world-location-news/264620.ja, content_store: live
      # keeping id: 285992, content_id: 60245adf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:59:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698530, content_id: 60245adf-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 16:59:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698530, content_id: "60245adf-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 16:59:11 UTC" },

      # base_path: /government/world-location-news/265215.ja, content_store: live
      # keeping id: 345895, content_id: 602582c5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698748, content_id: 602582c5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:18 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698748, content_id: "602582c5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:00:18 UTC" },

      # base_path: /government/world-location-news/265419.pt, content_store: live
      # keeping id: 404533, content_id: 6025e3f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698778, content_id: 6025e3f3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698778, content_id: "6025e3f3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:00:37 UTC" },

      # base_path: /government/world-location-news/265638.es-419, content_store: live
      # keeping id: 345896, content_id: 60265dc9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698816, content_id: 60265dc9-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698816, content_id: "60265dc9-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:00:57 UTC" },

      # base_path: /government/world-location-news/265644.pt, content_store: live
      # keeping id: 404534, content_id: 602660b7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:58 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698817, content_id: 602660b7-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698817, content_id: "602660b7-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:00:57 UTC" },

      # base_path: /government/world-location-news/265655.ja, content_store: live
      # keeping id: 285993, content_id: 602665d5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698820, content_id: 602665d5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698820, content_id: "602665d5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:00:59 UTC" },

      # base_path: /government/world-location-news/265657.ja, content_store: live
      # keeping id: 345897, content_id: 6026666f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698821, content_id: 6026666f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:00:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698821, content_id: "6026666f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:00:59 UTC" },

      # base_path: /government/world-location-news/266025.ja, content_store: live
      # keeping id: 285994, content_id: 602725c3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:01:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 698877, content_id: 602725c3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:01:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 698877, content_id: "602725c3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:01:39 UTC" },

      # base_path: /government/world-location-news/266786.cs, content_store: live
      # keeping id: 699010, content_id: 6028a3dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:03:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345898, content_id: 6028a3dc-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:03:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345898, content_id: "6028a3dc-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:03:06 UTC" },

      # base_path: /government/world-location-news/266820.pt, content_store: live
      # keeping id: 404535, content_id: 6028af2d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:03:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699013, content_id: 6028af2d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:03:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699013, content_id: "6028af2d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:03:09 UTC" },

      # base_path: /government/world-location-news/266908.pt, content_store: live
      # keeping id: 345899, content_id: 6028e32f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:03:18 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699021, content_id: 6028e32f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:03:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699021, content_id: "6028e32f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:03:17 UTC" },

      # base_path: /government/world-location-news/267540.es-419, content_store: live
      # keeping id: 345900, content_id: 602ad666-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:04:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699108, content_id: 602ad666-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:04:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699108, content_id: "602ad666-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:04:26 UTC" },

      # base_path: /government/world-location-news/267782.es-419, content_store: live
      # keeping id: 345901, content_id: 602b4606-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:04:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699154, content_id: 602b4606-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:04:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699154, content_id: "602b4606-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:04:51 UTC" },

      # base_path: /government/world-location-news/268305.es-419, content_store: live
      # keeping id: 345902, content_id: 602c6513-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699234, content_id: 602c6513-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699234, content_id: "602c6513-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:05:40 UTC" },

      # base_path: /government/world-location-news/268452.es-419, content_store: live
      # keeping id: 404536, content_id: 602cbef2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699258, content_id: 602cbef2-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699258, content_id: "602cbef2-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:05:55 UTC" },

      # base_path: /government/world-location-news/268479.zh-tw, content_store: live
      # keeping id: 404537, content_id: 602cc6fd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699266, content_id: 602cc6fd-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699266, content_id: "602cc6fd-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:05:58 UTC" },

      # base_path: /government/world-location-news/268483.zh-tw, content_store: draft
      # keeping id: 699272, content_id: 602cc9a4-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 17:06:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699271, content_id: 602cc9a4-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 17:06:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699271, content_id: "602cc9a4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:06:00 UTC" },

      # base_path: /government/world-location-news/268483.zh-tw, content_store: live
      # keeping id: 345903, content_id: 602cc9a4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699267, content_id: 602cc9a4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:05:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699267, content_id: "602cc9a4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:05:58 UTC" },

      # base_path: /government/world-location-news/269052.es-419, content_store: live
      # keeping id: 285995, content_id: 602de216-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699405, content_id: 602de216-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699405, content_id: "602de216-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:07:05 UTC" },

      # base_path: /government/world-location-news/269080.es-419, content_store: live
      # keeping id: 404538, content_id: 602dfbd0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699415, content_id: 602dfbd0-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699415, content_id: "602dfbd0-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:07:07 UTC" },

      # base_path: /government/world-location-news/269087.es-419, content_store: live
      # keeping id: 404539, content_id: 602e049f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699419, content_id: 602e049f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699419, content_id: "602e049f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:07:08 UTC" },

      # base_path: /government/world-location-news/269252.pt, content_store: live
      # keeping id: 404540, content_id: 602e548b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699479, content_id: 602e548b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:07:26 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699479, content_id: "602e548b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:07:26 UTC" },

      # base_path: /government/world-location-news/270327.es-419, content_store: live
      # keeping id: 404542, content_id: 60302a8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:09:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699659, content_id: 60302a8e-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:09:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699659, content_id: "60302a8e-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:09:16 UTC" },

      # base_path: /government/world-location-news/270679.pt, content_store: live
      # keeping id: 404543, content_id: 6030ee45-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:09:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699702, content_id: 6030ee45-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:09:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699702, content_id: "6030ee45-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:09:48 UTC" },

      # base_path: /government/world-location-news/270701.es-419, content_store: live
      # keeping id: 285996, content_id: 6031020b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:09:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699704, content_id: 6031020b-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:09:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699704, content_id: "6031020b-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:09:50 UTC" },

      # base_path: /government/world-location-news/271027.pt, content_store: live
      # keeping id: 404544, content_id: 6031bdf5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:10:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699773, content_id: 6031bdf5-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:10:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699773, content_id: "6031bdf5-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:10:21 UTC" },

      # base_path: /government/world-location-news/271230.pt, content_store: draft
      # keeping id: 699819, content_id: 60322479-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 17:10:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699818, content_id: 60322479-7631-11e4-a3cb-005056011aef, state: draft, updated_at: 2016-05-13 17:10:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699818, content_id: "60322479-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:10:41 UTC" },

      # base_path: /government/world-location-news/271245.pt, content_store: live
      # keeping id: 285997, content_id: 60322bb8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:10:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 699822, content_id: 60322bb8-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:10:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 699822, content_id: "60322bb8-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:10:43 UTC" },

      # base_path: /government/world-location-news/271936.es-419, content_store: live
      # keeping id: 404545, content_id: 60547854-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700044, content_id: 60547854-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700044, content_id: "60547854-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:11:38 UTC" },

      # base_path: /government/world-location-news/271974.es-419, content_store: live
      # keeping id: 404546, content_id: 60548725-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700051, content_id: 60548725-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700051, content_id: "60548725-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:11:42 UTC" },

      # base_path: /government/world-location-news/271975.es-419, content_store: live
      # keeping id: 285998, content_id: 6054876f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700053, content_id: 6054876f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700053, content_id: "6054876f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:11:42 UTC" },

      # base_path: /government/world-location-news/271976.es-419, content_store: live
      # keeping id: 345904, content_id: 605487be-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700052, content_id: 605487be-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700052, content_id: "605487be-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:11:42 UTC" },

      # base_path: /government/world-location-news/271980.es-419, content_store: live
      # keeping id: 345905, content_id: 605488ef-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700055, content_id: 605488ef-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700055, content_id: "605488ef-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:11:43 UTC" },

      # base_path: /government/world-location-news/271981.ja, content_store: live
      # keeping id: 404547, content_id: 6054893d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700056, content_id: 6054893d-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:11:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700056, content_id: "6054893d-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:11:43 UTC" },

      # base_path: /government/world-location-news/272153.es-419, content_store: live
      # keeping id: 404548, content_id: 6054e888-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:12:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700074, content_id: 6054e888-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:12:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700074, content_id: "6054e888-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:12:00 UTC" },

      # base_path: /government/world-location-news/272182.pt, content_store: live
      # keeping id: 345906, content_id: 605500c3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:12:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700076, content_id: 605500c3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:12:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700076, content_id: "605500c3-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:12:03 UTC" },

      # base_path: /government/world-location-news/272653.es-419, content_store: live
      # keeping id: 404549, content_id: 6055eea4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:12:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700188, content_id: 6055eea4-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:12:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700188, content_id: "6055eea4-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:12:49 UTC" },

      # base_path: /government/world-location-news/272820.es-419, content_store: live
      # keeping id: 404550, content_id: 60564219-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700280, content_id: 60564219-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700280, content_id: "60564219-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:13:01 UTC" },

      # base_path: /government/world-location-news/272824.zh, content_store: live
      # keeping id: 285999, content_id: 6056434f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700282, content_id: 6056434f-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:02 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700282, content_id: "6056434f-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:13:02 UTC" },

      # base_path: /government/world-location-news/272888.ro, content_store: live
      # keeping id: 345907, content_id: 60567448-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700288, content_id: 60567448-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700288, content_id: "60567448-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:13:08 UTC" },

      # base_path: /government/world-location-news/273314.es-419, content_store: live
      # keeping id: 404551, content_id: 60572ff1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700373, content_id: 60572ff1-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-13 17:13:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700373, content_id: "60572ff1-7631-11e4-a3cb-005056011aef", updated_at: "2016-05-13 17:13:44 UTC" },

      # base_path: /government/world-location-news/273582.es-419, content_store: live
      # keeping id: 345908, content_id: 758ee904-d356-4411-9769-ecf407799233, state: published, updated_at: 2016-05-13 17:14:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700393, content_id: 758ee904-d356-4411-9769-ecf407799233, state: published, updated_at: 2016-05-13 17:14:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700393, content_id: "758ee904-d356-4411-9769-ecf407799233", updated_at: "2016-05-13 17:14:11 UTC" },

      # base_path: /government/world-location-news/273585.es-419, content_store: live
      # keeping id: 404552, content_id: f3a0159a-b7b9-4df9-bf6f-a6b1f3fae05c, state: published, updated_at: 2016-05-13 17:14:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700394, content_id: f3a0159a-b7b9-4df9-bf6f-a6b1f3fae05c, state: published, updated_at: 2016-05-13 17:14:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700394, content_id: "f3a0159a-b7b9-4df9-bf6f-a6b1f3fae05c", updated_at: "2016-05-13 17:14:12 UTC" },

      # base_path: /government/world-location-news/274156.es, content_store: live
      # keeping id: 404553, content_id: f720881a-3c9b-46a4-8791-247cf5bee590, state: published, updated_at: 2016-05-13 17:15:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700664, content_id: f720881a-3c9b-46a4-8791-247cf5bee590, state: published, updated_at: 2016-05-13 17:15:11 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700664, content_id: "f720881a-3c9b-46a4-8791-247cf5bee590", updated_at: "2016-05-13 17:15:11 UTC" },

      # base_path: /government/world-location-news/274722.zh, content_store: live
      # keeping id: 345909, content_id: 58d909ab-6c7d-4d56-b301-50282de32430, state: published, updated_at: 2016-05-13 17:16:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700788, content_id: 58d909ab-6c7d-4d56-b301-50282de32430, state: published, updated_at: 2016-05-13 17:16:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700788, content_id: "58d909ab-6c7d-4d56-b301-50282de32430", updated_at: "2016-05-13 17:16:07 UTC" },

      # base_path: /government/world-location-news/274901.fr, content_store: live
      # keeping id: 404554, content_id: 58734655-e492-472f-8f16-780fc5660879, state: published, updated_at: 2016-05-13 17:16:27 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700830, content_id: 58734655-e492-472f-8f16-780fc5660879, state: published, updated_at: 2016-05-13 17:16:27 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700830, content_id: "58734655-e492-472f-8f16-780fc5660879", updated_at: "2016-05-13 17:16:27 UTC" },

      # base_path: /government/world-location-news/274977.uk, content_store: live
      # keeping id: 404555, content_id: 983320a7-28d5-433a-88fe-3f083e414fa0, state: published, updated_at: 2016-05-13 17:16:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700849, content_id: 983320a7-28d5-433a-88fe-3f083e414fa0, state: published, updated_at: 2016-05-13 17:16:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700849, content_id: "983320a7-28d5-433a-88fe-3f083e414fa0", updated_at: "2016-05-13 17:16:35 UTC" },

      # base_path: /government/world-location-news/275112.pt, content_store: live
      # keeping id: 404556, content_id: 50359da0-8f48-4641-a63e-f4225c7daf28, state: published, updated_at: 2016-05-13 17:16:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700874, content_id: 50359da0-8f48-4641-a63e-f4225c7daf28, state: published, updated_at: 2016-05-13 17:16:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700874, content_id: "50359da0-8f48-4641-a63e-f4225c7daf28", updated_at: "2016-05-13 17:16:48 UTC" },

      # base_path: /government/world-location-news/275213.pt, content_store: live
      # keeping id: 286000, content_id: 30142bbf-06b0-4788-bbcb-a66d96de738d, state: published, updated_at: 2016-05-13 17:16:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 700885, content_id: 30142bbf-06b0-4788-bbcb-a66d96de738d, state: published, updated_at: 2016-05-13 17:16:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 700885, content_id: "30142bbf-06b0-4788-bbcb-a66d96de738d", updated_at: "2016-05-13 17:16:58 UTC" },

      # base_path: /government/world-location-news/275931.es, content_store: live
      # keeping id: 286001, content_id: f8fdb6b8-8e08-4490-9c99-cb5620b8be3f, state: published, updated_at: 2016-05-13 17:18:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701023, content_id: f8fdb6b8-8e08-4490-9c99-cb5620b8be3f, state: published, updated_at: 2016-05-13 17:18:17 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701023, content_id: "f8fdb6b8-8e08-4490-9c99-cb5620b8be3f", updated_at: "2016-05-13 17:18:17 UTC" },

      # base_path: /government/world-location-news/276130.es, content_store: live
      # keeping id: 404557, content_id: 36d6b77b-9030-4bee-be7e-352419c33657, state: published, updated_at: 2016-05-13 17:18:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701035, content_id: 36d6b77b-9030-4bee-be7e-352419c33657, state: published, updated_at: 2016-05-13 17:18:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701035, content_id: "36d6b77b-9030-4bee-be7e-352419c33657", updated_at: "2016-05-13 17:18:37 UTC" },

      # base_path: /government/world-location-news/276545.es-419, content_store: live
      # keeping id: 404558, content_id: 1249cde5-c4f4-4d27-9888-ae6635302195, state: published, updated_at: 2016-05-13 17:19:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701071, content_id: 1249cde5-c4f4-4d27-9888-ae6635302195, state: published, updated_at: 2016-05-13 17:19:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701071, content_id: "1249cde5-c4f4-4d27-9888-ae6635302195", updated_at: "2016-05-13 17:19:13 UTC" },

      # base_path: /government/world-location-news/276559.zh-tw, content_store: live
      # keeping id: 404559, content_id: ac6962d4-8a39-4d58-954f-2274b6ba269e, state: published, updated_at: 2016-05-13 17:19:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701082, content_id: ac6962d4-8a39-4d58-954f-2274b6ba269e, state: published, updated_at: 2016-05-13 17:19:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701082, content_id: "ac6962d4-8a39-4d58-954f-2274b6ba269e", updated_at: "2016-05-13 17:19:15 UTC" },

      # base_path: /government/world-location-news/276977.pt, content_store: live
      # keeping id: 404560, content_id: 5578e356-3be5-476a-8ec1-0a170235624c, state: published, updated_at: 2016-05-13 17:19:58 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701138, content_id: 5578e356-3be5-476a-8ec1-0a170235624c, state: published, updated_at: 2016-05-13 17:19:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701138, content_id: "5578e356-3be5-476a-8ec1-0a170235624c", updated_at: "2016-05-13 17:19:57 UTC" },

      # base_path: /government/world-location-news/277471.lt, content_store: draft
      # keeping id: 701233, content_id: 92f25a0b-2538-4eeb-8915-d061e02f14ab, state: draft, updated_at: 2016-05-13 17:20:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701230, content_id: 92f25a0b-2538-4eeb-8915-d061e02f14ab, state: draft, updated_at: 2016-05-13 17:20:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701230, content_id: "92f25a0b-2538-4eeb-8915-d061e02f14ab", updated_at: "2016-05-13 17:20:48 UTC" },

      # base_path: /government/world-location-news/277472.lt, content_store: draft
      # keeping id: 701234, content_id: 0215902d-5f46-433a-a417-f00d1750f70e, state: draft, updated_at: 2016-05-13 17:20:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701231, content_id: 0215902d-5f46-433a-a417-f00d1750f70e, state: draft, updated_at: 2016-05-13 17:20:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701231, content_id: "0215902d-5f46-433a-a417-f00d1750f70e", updated_at: "2016-05-13 17:20:48 UTC" },

      # base_path: /government/world-location-news/277486.lt, content_store: live
      # keeping id: 404561, content_id: 404e4810-b05c-4caa-a7de-123836f228d2, state: published, updated_at: 2016-05-13 17:20:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701236, content_id: 404e4810-b05c-4caa-a7de-123836f228d2, state: published, updated_at: 2016-05-13 17:20:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701236, content_id: "404e4810-b05c-4caa-a7de-123836f228d2", updated_at: "2016-05-13 17:20:49 UTC" },

      # base_path: /government/world-location-news/277623.zh-tw, content_store: live
      # keeping id: 345910, content_id: 54e3d137-b08f-497c-965a-5a69048370da, state: published, updated_at: 2016-05-13 17:21:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701255, content_id: 54e3d137-b08f-497c-965a-5a69048370da, state: published, updated_at: 2016-05-13 17:21:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701255, content_id: "54e3d137-b08f-497c-965a-5a69048370da", updated_at: "2016-05-13 17:21:03 UTC" },

      # base_path: /government/world-location-news/277800.el, content_store: live
      # keeping id: 701276, content_id: 03e39c42-f15d-419f-87c3-1eef25103c91, state: published, updated_at: 2016-05-13 17:21:23 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 286002, content_id: 03e39c42-f15d-419f-87c3-1eef25103c91, state: published, updated_at: 2016-05-13 17:21:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 286002, content_id: "03e39c42-f15d-419f-87c3-1eef25103c91", updated_at: "2016-05-13 17:21:22 UTC" },

      # base_path: /government/world-location-news/277968.lt, content_store: live
      # keeping id: 345911, content_id: b0e01f39-954c-496d-96ad-3b801cf5333e, state: published, updated_at: 2016-05-13 17:21:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701295, content_id: b0e01f39-954c-496d-96ad-3b801cf5333e, state: published, updated_at: 2016-05-13 17:21:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701295, content_id: "b0e01f39-954c-496d-96ad-3b801cf5333e", updated_at: "2016-05-13 17:21:39 UTC" },

      # base_path: /government/world-location-news/278088.fr, content_store: live
      # keeping id: 404562, content_id: 77aa5454-b12d-4ac4-8a52-6646935473f5, state: published, updated_at: 2016-05-13 17:21:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701320, content_id: 77aa5454-b12d-4ac4-8a52-6646935473f5, state: published, updated_at: 2016-05-13 17:21:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701320, content_id: "77aa5454-b12d-4ac4-8a52-6646935473f5", updated_at: "2016-05-13 17:21:50 UTC" },

      # base_path: /government/world-location-news/278419.es-419, content_store: live
      # keeping id: 404563, content_id: ed137541-a5d8-41ec-b156-96cc3412b705, state: published, updated_at: 2016-05-13 17:22:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701376, content_id: ed137541-a5d8-41ec-b156-96cc3412b705, state: published, updated_at: 2016-05-13 17:22:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701376, content_id: "ed137541-a5d8-41ec-b156-96cc3412b705", updated_at: "2016-05-13 17:22:20 UTC" },

      # base_path: /government/world-location-news/278578.es-419, content_store: live
      # keeping id: 404565, content_id: f749dd10-f3df-4ae1-9074-7ef50948ab22, state: published, updated_at: 2016-05-13 17:22:36 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701395, content_id: f749dd10-f3df-4ae1-9074-7ef50948ab22, state: published, updated_at: 2016-05-13 17:22:36 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701395, content_id: "f749dd10-f3df-4ae1-9074-7ef50948ab22", updated_at: "2016-05-13 17:22:36 UTC" },

      # base_path: /government/world-location-news/278993.de, content_store: live
      # keeping id: 701463, content_id: 61d28ee4-5c10-49be-988d-6153e4706748, state: published, updated_at: 2016-05-13 17:23:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404566, content_id: 61d28ee4-5c10-49be-988d-6153e4706748, state: published, updated_at: 2016-05-13 17:23:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404566, content_id: "61d28ee4-5c10-49be-988d-6153e4706748", updated_at: "2016-05-13 17:23:14 UTC" },

      # base_path: /government/world-location-news/279743.es, content_store: live
      # keeping id: 404567, content_id: 4ee38c7d-5aad-40f1-a8b0-9b2b2d0eabb4, state: published, updated_at: 2016-05-13 17:24:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701529, content_id: 4ee38c7d-5aad-40f1-a8b0-9b2b2d0eabb4, state: published, updated_at: 2016-05-13 17:24:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701529, content_id: "4ee38c7d-5aad-40f1-a8b0-9b2b2d0eabb4", updated_at: "2016-05-13 17:24:28 UTC" },

      # base_path: /government/world-location-news/279923.es, content_store: live
      # keeping id: 404568, content_id: a6033386-f856-4eb2-96fa-58b22816519e, state: published, updated_at: 2016-05-13 17:24:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701559, content_id: a6033386-f856-4eb2-96fa-58b22816519e, state: published, updated_at: 2016-05-13 17:24:45 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701559, content_id: "a6033386-f856-4eb2-96fa-58b22816519e", updated_at: "2016-05-13 17:24:45 UTC" },

      # base_path: /government/world-location-news/280299.es-419, content_store: live
      # keeping id: 404569, content_id: 5f4801b4-eccd-4024-8f3e-9d532c8f7de5, state: published, updated_at: 2016-05-13 17:25:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701628, content_id: 5f4801b4-eccd-4024-8f3e-9d532c8f7de5, state: published, updated_at: 2016-05-13 17:25:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701628, content_id: "5f4801b4-eccd-4024-8f3e-9d532c8f7de5", updated_at: "2016-05-13 17:25:21 UTC" },

      # base_path: /government/world-location-news/281177.ru, content_store: live
      # keeping id: 286004, content_id: 3b277b12-85c9-48b0-a8c6-2fbf6cc82cb0, state: published, updated_at: 2016-05-13 17:26:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701737, content_id: 3b277b12-85c9-48b0-a8c6-2fbf6cc82cb0, state: published, updated_at: 2016-05-13 17:26:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701737, content_id: "3b277b12-85c9-48b0-a8c6-2fbf6cc82cb0", updated_at: "2016-05-13 17:26:41 UTC" },

      # base_path: /government/world-location-news/281728.es-419, content_store: live
      # keeping id: 286005, content_id: ca81b57b-7f69-4af0-9ee7-6227afe2f84b, state: published, updated_at: 2016-05-13 17:27:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701827, content_id: ca81b57b-7f69-4af0-9ee7-6227afe2f84b, state: published, updated_at: 2016-05-13 17:27:31 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701827, content_id: "ca81b57b-7f69-4af0-9ee7-6227afe2f84b", updated_at: "2016-05-13 17:27:31 UTC" },

      # base_path: /government/world-location-news/282153.zh-tw, content_store: live
      # keeping id: 404570, content_id: 242c2306-2684-4ee5-883f-bedefc46249b, state: published, updated_at: 2016-05-13 17:28:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701882, content_id: 242c2306-2684-4ee5-883f-bedefc46249b, state: published, updated_at: 2016-05-13 17:28:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701882, content_id: "242c2306-2684-4ee5-883f-bedefc46249b", updated_at: "2016-05-13 17:28:12 UTC" },

      # base_path: /government/world-location-news/282154.el, content_store: live
      # keeping id: 701884, content_id: b2fe91a6-45ab-4ebf-a356-961e714eb6af, state: published, updated_at: 2016-05-13 17:28:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 286006, content_id: b2fe91a6-45ab-4ebf-a356-961e714eb6af, state: published, updated_at: 2016-05-13 17:28:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 286006, content_id: "b2fe91a6-45ab-4ebf-a356-961e714eb6af", updated_at: "2016-05-13 17:28:12 UTC" },

      # base_path: /government/world-location-news/282318.pt, content_store: live
      # keeping id: 286007, content_id: 6f5039ed-5b83-4213-9224-bdad0bc3d77f, state: published, updated_at: 2016-05-13 17:28:28 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701899, content_id: 6f5039ed-5b83-4213-9224-bdad0bc3d77f, state: published, updated_at: 2016-05-13 17:28:28 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701899, content_id: "6f5039ed-5b83-4213-9224-bdad0bc3d77f", updated_at: "2016-05-13 17:28:28 UTC" },

      # base_path: /government/world-location-news/282389.zh, content_store: draft
      # keeping id: 701905, content_id: 44cedcb1-2375-4fc2-b3dd-b0338da89db2, state: draft, updated_at: 2016-05-13 17:28:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345912, content_id: 44cedcb1-2375-4fc2-b3dd-b0338da89db2, state: draft, updated_at: 2016-05-13 17:28:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345912, content_id: "44cedcb1-2375-4fc2-b3dd-b0338da89db2", updated_at: "2016-05-13 17:28:34 UTC" },

      # base_path: /government/world-location-news/282404.zh, content_store: live
      # keeping id: 345913, content_id: 49cd9cd7-25f6-4224-9a4c-d8e19016900e, state: published, updated_at: 2016-05-13 17:28:36 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701907, content_id: 49cd9cd7-25f6-4224-9a4c-d8e19016900e, state: published, updated_at: 2016-05-13 17:28:36 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701907, content_id: "49cd9cd7-25f6-4224-9a4c-d8e19016900e", updated_at: "2016-05-13 17:28:36 UTC" },

      # base_path: /government/world-location-news/282671.pt, content_store: live
      # keeping id: 404571, content_id: 3dff4592-8a50-4a9c-86bf-c596f9008b4d, state: published, updated_at: 2016-05-13 17:29:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701934, content_id: 3dff4592-8a50-4a9c-86bf-c596f9008b4d, state: published, updated_at: 2016-05-13 17:29:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701934, content_id: "3dff4592-8a50-4a9c-86bf-c596f9008b4d", updated_at: "2016-05-13 17:29:01 UTC" },

      # base_path: /government/world-location-news/282701.lt, content_store: live
      # keeping id: 404572, content_id: eed3c99f-2d64-41eb-955b-d5d613ee3b09, state: published, updated_at: 2016-05-13 17:29:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701937, content_id: eed3c99f-2d64-41eb-955b-d5d613ee3b09, state: published, updated_at: 2016-05-13 17:29:04 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701937, content_id: "eed3c99f-2d64-41eb-955b-d5d613ee3b09", updated_at: "2016-05-13 17:29:04 UTC" },

      # base_path: /government/world-location-news/282770.es, content_store: live
      # keeping id: 404573, content_id: cdc6a3d8-27fc-4ed1-b128-0a2f7bf79678, state: published, updated_at: 2016-05-13 17:29:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701947, content_id: cdc6a3d8-27fc-4ed1-b128-0a2f7bf79678, state: published, updated_at: 2016-05-13 17:29:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701947, content_id: "cdc6a3d8-27fc-4ed1-b128-0a2f7bf79678", updated_at: "2016-05-13 17:29:12 UTC" },

      # base_path: /government/world-location-news/283262.es-419, content_store: live
      # keeping id: 345914, content_id: 381cbe60-9a2a-4dab-a622-41cb0480aaad, state: published, updated_at: 2016-05-13 17:30:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701992, content_id: 381cbe60-9a2a-4dab-a622-41cb0480aaad, state: published, updated_at: 2016-05-13 17:30:02 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701992, content_id: "381cbe60-9a2a-4dab-a622-41cb0480aaad", updated_at: "2016-05-13 17:30:02 UTC" },

      # base_path: /government/world-location-news/283286.zh-tw, content_store: live
      # keeping id: 345915, content_id: 628779b9-32d5-448f-a079-31d3dfa1c6b9, state: published, updated_at: 2016-05-13 17:30:05 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 701998, content_id: 628779b9-32d5-448f-a079-31d3dfa1c6b9, state: published, updated_at: 2016-05-13 17:30:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 701998, content_id: "628779b9-32d5-448f-a079-31d3dfa1c6b9", updated_at: "2016-05-13 17:30:05 UTC" },

      # base_path: /government/world-location-news/283332.es, content_store: live
      # keeping id: 404574, content_id: 64798477-67e6-4c36-99e1-9c2946330cfe, state: published, updated_at: 2016-05-13 17:30:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702000, content_id: 64798477-67e6-4c36-99e1-9c2946330cfe, state: published, updated_at: 2016-05-13 17:30:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702000, content_id: "64798477-67e6-4c36-99e1-9c2946330cfe", updated_at: "2016-05-13 17:30:12 UTC" },

      # base_path: /government/world-location-news/283719.es-419, content_store: draft
      # keeping id: 702062, content_id: 277cf285-b83c-4177-ac77-65b3625299e1, state: draft, updated_at: 2016-05-13 17:30:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702061, content_id: 277cf285-b83c-4177-ac77-65b3625299e1, state: draft, updated_at: 2016-05-13 17:30:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702061, content_id: "277cf285-b83c-4177-ac77-65b3625299e1", updated_at: "2016-05-13 17:30:53 UTC" },

      # base_path: /government/world-location-news/283719.es-419, content_store: live
      # keeping id: 404575, content_id: 277cf285-b83c-4177-ac77-65b3625299e1, state: published, updated_at: 2016-05-13 17:30:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702056, content_id: 277cf285-b83c-4177-ac77-65b3625299e1, state: published, updated_at: 2016-05-13 17:30:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702056, content_id: "277cf285-b83c-4177-ac77-65b3625299e1", updated_at: "2016-05-13 17:30:52 UTC" },

      # base_path: /government/world-location-news/283726.es-419, content_store: draft
      # keeping id: 702064, content_id: 187eafe8-006c-435d-bc22-7beef23070d5, state: draft, updated_at: 2016-05-13 17:30:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702063, content_id: 187eafe8-006c-435d-bc22-7beef23070d5, state: draft, updated_at: 2016-05-13 17:30:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702063, content_id: "187eafe8-006c-435d-bc22-7beef23070d5", updated_at: "2016-05-13 17:30:53 UTC" },

      # base_path: /government/world-location-news/283726.es-419, content_store: live
      # keeping id: 345916, content_id: 187eafe8-006c-435d-bc22-7beef23070d5, state: published, updated_at: 2016-05-13 17:30:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702057, content_id: 187eafe8-006c-435d-bc22-7beef23070d5, state: published, updated_at: 2016-05-13 17:30:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702057, content_id: "187eafe8-006c-435d-bc22-7beef23070d5", updated_at: "2016-05-13 17:30:52 UTC" },

      # base_path: /government/world-location-news/284117.pt, content_store: live
      # keeping id: 345829, content_id: 71e1f40e-c5c3-41b6-a93d-6043db0f57ea, state: published, updated_at: 2016-05-13 17:31:32 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702112, content_id: 71e1f40e-c5c3-41b6-a93d-6043db0f57ea, state: published, updated_at: 2016-05-13 17:31:32 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702112, content_id: "71e1f40e-c5c3-41b6-a93d-6043db0f57ea", updated_at: "2016-05-13 17:31:32 UTC" },

      # base_path: /government/world-location-news/284564.es-419, content_store: live
      # keeping id: 286008, content_id: 62433ea8-acf4-4add-8a75-2d3bf10a88d4, state: published, updated_at: 2016-05-13 17:32:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702180, content_id: 62433ea8-acf4-4add-8a75-2d3bf10a88d4, state: published, updated_at: 2016-05-13 17:32:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702180, content_id: "62433ea8-acf4-4add-8a75-2d3bf10a88d4", updated_at: "2016-05-13 17:32:16 UTC" },

      # base_path: /government/world-location-news/284716.pt, content_store: live
      # keeping id: 286009, content_id: 98226a90-00c8-42a2-9a27-e600db178eed, state: published, updated_at: 2016-05-13 17:32:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702196, content_id: 98226a90-00c8-42a2-9a27-e600db178eed, state: published, updated_at: 2016-05-13 17:32:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702196, content_id: "98226a90-00c8-42a2-9a27-e600db178eed", updated_at: "2016-05-13 17:32:34 UTC" },

      # base_path: /government/world-location-news/284721.es-419, content_store: live
      # keeping id: 345917, content_id: fafd31ea-24b8-472a-89a8-27aa76488f1a, state: published, updated_at: 2016-05-13 17:32:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702198, content_id: fafd31ea-24b8-472a-89a8-27aa76488f1a, state: published, updated_at: 2016-05-13 17:32:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702198, content_id: "fafd31ea-24b8-472a-89a8-27aa76488f1a", updated_at: "2016-05-13 17:32:34 UTC" },

      # base_path: /government/world-location-news/284868.es-419, content_store: live
      # keeping id: 345918, content_id: 6cea1571-43e7-4bbd-b81e-c0aedbfc8dd9, state: published, updated_at: 2016-05-13 17:32:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702217, content_id: 6cea1571-43e7-4bbd-b81e-c0aedbfc8dd9, state: published, updated_at: 2016-05-13 17:32:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702217, content_id: "6cea1571-43e7-4bbd-b81e-c0aedbfc8dd9", updated_at: "2016-05-13 17:32:49 UTC" },

      # base_path: /government/world-location-news/285657.pt, content_store: live
      # keeping id: 345919, content_id: e48597c2-a77d-4bb0-b173-f3aa3e9f64b4, state: published, updated_at: 2016-05-13 17:34:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702342, content_id: e48597c2-a77d-4bb0-b173-f3aa3e9f64b4, state: published, updated_at: 2016-05-13 17:34:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702342, content_id: "e48597c2-a77d-4bb0-b173-f3aa3e9f64b4", updated_at: "2016-05-13 17:34:08 UTC" },

      # base_path: /government/world-location-news/285666.pt, content_store: live
      # keeping id: 404576, content_id: 4929267b-aaa5-4e61-9978-0ac1cf6f5ee5, state: published, updated_at: 2016-05-13 17:34:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702345, content_id: 4929267b-aaa5-4e61-9978-0ac1cf6f5ee5, state: published, updated_at: 2016-05-13 17:34:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702345, content_id: "4929267b-aaa5-4e61-9978-0ac1cf6f5ee5", updated_at: "2016-05-13 17:34:10 UTC" },

      # base_path: /government/world-location-news/285667.es-419, content_store: live
      # keeping id: 404577, content_id: 5804bed5-2caf-4058-a222-50f7e4321a3b, state: published, updated_at: 2016-05-13 17:34:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702344, content_id: 5804bed5-2caf-4058-a222-50f7e4321a3b, state: published, updated_at: 2016-05-13 17:34:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702344, content_id: "5804bed5-2caf-4058-a222-50f7e4321a3b", updated_at: "2016-05-13 17:34:10 UTC" },

      # base_path: /government/world-location-news/286041.es-419, content_store: draft
      # keeping id: 702486, content_id: 550f0c73-edf7-496e-9c74-b29b3c41189b, state: draft, updated_at: 2016-05-13 17:34:49 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702485, content_id: 550f0c73-edf7-496e-9c74-b29b3c41189b, state: draft, updated_at: 2016-05-13 17:34:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702485, content_id: "550f0c73-edf7-496e-9c74-b29b3c41189b", updated_at: "2016-05-13 17:34:49 UTC" },

      # base_path: /government/world-location-news/286041.es-419, content_store: live
      # keeping id: 286010, content_id: 550f0c73-edf7-496e-9c74-b29b3c41189b, state: published, updated_at: 2016-05-13 17:34:48 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702480, content_id: 550f0c73-edf7-496e-9c74-b29b3c41189b, state: published, updated_at: 2016-05-13 17:34:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702480, content_id: "550f0c73-edf7-496e-9c74-b29b3c41189b", updated_at: "2016-05-13 17:34:47 UTC" },

      # base_path: /government/world-location-news/286083.pt, content_store: live
      # keeping id: 345920, content_id: 81d56776-7649-4a35-b8a4-f3e8dfafd89b, state: published, updated_at: 2016-05-13 17:34:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702488, content_id: 81d56776-7649-4a35-b8a4-f3e8dfafd89b, state: published, updated_at: 2016-05-13 17:34:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702488, content_id: "81d56776-7649-4a35-b8a4-f3e8dfafd89b", updated_at: "2016-05-13 17:34:51 UTC" },

      # base_path: /government/world-location-news/286183.es, content_store: live
      # keeping id: 286011, content_id: d480c517-cf91-48f4-b66c-5fd9785e9238, state: published, updated_at: 2016-05-13 17:35:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702501, content_id: d480c517-cf91-48f4-b66c-5fd9785e9238, state: published, updated_at: 2016-05-13 17:35:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702501, content_id: "d480c517-cf91-48f4-b66c-5fd9785e9238", updated_at: "2016-05-13 17:35:01 UTC" },

      # base_path: /government/world-location-news/286234.pt, content_store: live
      # keeping id: 345921, content_id: 7c29a7ef-693d-4715-a71b-bcb78b2cfcca, state: published, updated_at: 2016-05-13 17:35:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702502, content_id: 7c29a7ef-693d-4715-a71b-bcb78b2cfcca, state: published, updated_at: 2016-05-13 17:35:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702502, content_id: "7c29a7ef-693d-4715-a71b-bcb78b2cfcca", updated_at: "2016-05-13 17:35:06 UTC" },

      # base_path: /government/world-location-news/286266.es, content_store: live
      # keeping id: 286012, content_id: 85a3e3ec-d1f7-4857-84d8-7d7d490d4007, state: published, updated_at: 2016-05-13 17:35:11 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702509, content_id: 85a3e3ec-d1f7-4857-84d8-7d7d490d4007, state: published, updated_at: 2016-05-13 17:35:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702509, content_id: "85a3e3ec-d1f7-4857-84d8-7d7d490d4007", updated_at: "2016-05-13 17:35:09 UTC" },

      # base_path: /government/world-location-news/286425.ja, content_store: live
      # keeping id: 286013, content_id: e3eb02db-2242-4d69-9f93-2a7731499f16, state: published, updated_at: 2016-05-13 17:35:29 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702525, content_id: e3eb02db-2242-4d69-9f93-2a7731499f16, state: published, updated_at: 2016-05-13 17:35:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702525, content_id: "e3eb02db-2242-4d69-9f93-2a7731499f16", updated_at: "2016-05-13 17:35:29 UTC" },

      # base_path: /government/world-location-news/286926.zh, content_store: live
      # keeping id: 404578, content_id: 628de23e-dac9-41cc-a5b8-fc012a0f4a62, state: published, updated_at: 2016-05-13 17:36:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702587, content_id: 628de23e-dac9-41cc-a5b8-fc012a0f4a62, state: published, updated_at: 2016-05-13 17:36:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702587, content_id: "628de23e-dac9-41cc-a5b8-fc012a0f4a62", updated_at: "2016-05-13 17:36:22 UTC" },

      # base_path: /government/world-location-news/286929.zh-tw, content_store: draft
      # keeping id: 702589, content_id: 9a57d1ec-86b4-431d-b350-c17235de1902, state: draft, updated_at: 2016-05-13 17:36:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702588, content_id: 9a57d1ec-86b4-431d-b350-c17235de1902, state: draft, updated_at: 2016-05-13 17:36:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702588, content_id: "9a57d1ec-86b4-431d-b350-c17235de1902", updated_at: "2016-05-13 17:36:22 UTC" },

      # base_path: /government/world-location-news/287032.es-419, content_store: live
      # keeping id: 713769, content_id: 6248434d-5f2a-4f61-97bd-974714a2e0bf, state: published, updated_at: 2016-05-13 18:46:30 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 713767, content_id: 6248434d-5f2a-4f61-97bd-974714a2e0bf, state: published, updated_at: 2016-05-13 18:46:29 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 713767, content_id: "6248434d-5f2a-4f61-97bd-974714a2e0bf", updated_at: "2016-05-13 18:46:29 UTC" },

      # base_path: /government/world-location-news/287200.es, content_store: draft
      # keeping id: 702634, content_id: aa8ecff0-4d50-4a7e-80af-2fe581320a81, state: draft, updated_at: 2016-05-13 17:36:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702633, content_id: aa8ecff0-4d50-4a7e-80af-2fe581320a81, state: draft, updated_at: 2016-05-13 17:36:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702633, content_id: "aa8ecff0-4d50-4a7e-80af-2fe581320a81", updated_at: "2016-05-13 17:36:59 UTC" },

      # base_path: /government/world-location-news/287200.es, content_store: live
      # keeping id: 404580, content_id: aa8ecff0-4d50-4a7e-80af-2fe581320a81, state: published, updated_at: 2016-05-13 17:36:58 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702631, content_id: aa8ecff0-4d50-4a7e-80af-2fe581320a81, state: published, updated_at: 2016-05-13 17:36:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702631, content_id: "aa8ecff0-4d50-4a7e-80af-2fe581320a81", updated_at: "2016-05-13 17:36:57 UTC" },

      # base_path: /government/world-location-news/287786.es-419, content_store: live
      # keeping id: 286014, content_id: dff0020e-9663-4ac2-a9c5-a8e94bb55216, state: published, updated_at: 2016-05-13 17:38:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702722, content_id: dff0020e-9663-4ac2-a9c5-a8e94bb55216, state: published, updated_at: 2016-05-13 17:37:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702722, content_id: "dff0020e-9663-4ac2-a9c5-a8e94bb55216", updated_at: "2016-05-13 17:37:59 UTC" },

      # base_path: /government/world-location-news/287819.es-419, content_store: live
      # keeping id: 345922, content_id: 7dd45f44-81a4-4006-b156-d450174368fc, state: published, updated_at: 2016-05-13 17:38:03 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702729, content_id: 7dd45f44-81a4-4006-b156-d450174368fc, state: published, updated_at: 2016-05-13 17:38:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702729, content_id: "7dd45f44-81a4-4006-b156-d450174368fc", updated_at: "2016-05-13 17:38:03 UTC" },

      # base_path: /government/world-location-news/287987.pt, content_store: live
      # keeping id: 286015, content_id: 35b3bd96-486a-4726-b6d6-4ad1caa101d5, state: published, updated_at: 2016-05-13 17:38:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702746, content_id: 35b3bd96-486a-4726-b6d6-4ad1caa101d5, state: published, updated_at: 2016-05-13 17:38:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702746, content_id: "35b3bd96-486a-4726-b6d6-4ad1caa101d5", updated_at: "2016-05-13 17:38:22 UTC" },

      # base_path: /government/world-location-news/288732.pt, content_store: live
      # keeping id: 404581, content_id: 80f809de-3351-4ad9-b7e9-8b4ef2d2a1d2, state: published, updated_at: 2016-05-13 17:39:56 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702876, content_id: 80f809de-3351-4ad9-b7e9-8b4ef2d2a1d2, state: published, updated_at: 2016-05-13 17:39:55 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702876, content_id: "80f809de-3351-4ad9-b7e9-8b4ef2d2a1d2", updated_at: "2016-05-13 17:39:55 UTC" },

      # base_path: /government/world-location-news/288819.pt, content_store: live
      # keeping id: 404582, content_id: 06584295-cba1-41d5-a55d-af7d2925b389, state: published, updated_at: 2016-05-13 17:40:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702887, content_id: 06584295-cba1-41d5-a55d-af7d2925b389, state: published, updated_at: 2016-05-13 17:40:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702887, content_id: "06584295-cba1-41d5-a55d-af7d2925b389", updated_at: "2016-05-13 17:40:06 UTC" },

      # base_path: /government/world-location-news/288939.ar, content_store: live
      # keeping id: 702913, content_id: aead3b2d-5947-44c6-9142-0a935b89220b, state: published, updated_at: 2016-05-13 17:40:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345923, content_id: aead3b2d-5947-44c6-9142-0a935b89220b, state: published, updated_at: 2016-05-13 17:40:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345923, content_id: "aead3b2d-5947-44c6-9142-0a935b89220b", updated_at: "2016-05-13 17:40:20 UTC" },

      # base_path: /government/world-location-news/288940.pt, content_store: live
      # keeping id: 286016, content_id: 6848648e-330c-48f0-bc2a-4f8d382c23f7, state: published, updated_at: 2016-05-13 17:40:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702910, content_id: 6848648e-330c-48f0-bc2a-4f8d382c23f7, state: published, updated_at: 2016-05-13 17:40:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702910, content_id: "6848648e-330c-48f0-bc2a-4f8d382c23f7", updated_at: "2016-05-13 17:40:21 UTC" },

      # base_path: /government/world-location-news/289040.es, content_store: draft
      # keeping id: 702930, content_id: d5aca77c-0873-4347-bdca-314eee492482, state: draft, updated_at: 2016-05-13 17:40:34 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702928, content_id: d5aca77c-0873-4347-bdca-314eee492482, state: draft, updated_at: 2016-05-13 17:40:34 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702928, content_id: "d5aca77c-0873-4347-bdca-314eee492482", updated_at: "2016-05-13 17:40:34 UTC" },

      # base_path: /government/world-location-news/289081.es, content_store: live
      # keeping id: 286017, content_id: d9367a6a-3116-4513-8ec7-3faaf3321732, state: published, updated_at: 2016-05-13 17:40:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702941, content_id: d9367a6a-3116-4513-8ec7-3faaf3321732, state: published, updated_at: 2016-05-13 17:40:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702941, content_id: "d9367a6a-3116-4513-8ec7-3faaf3321732", updated_at: "2016-05-13 17:40:38 UTC" },

      # base_path: /government/world-location-news/289124.cs, content_store: live
      # keeping id: 702953, content_id: d87c8c9e-a6c3-4844-b920-be2ab04c0717, state: published, updated_at: 2016-05-13 17:40:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404583, content_id: d87c8c9e-a6c3-4844-b920-be2ab04c0717, state: published, updated_at: 2016-05-13 17:40:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404583, content_id: "d87c8c9e-a6c3-4844-b920-be2ab04c0717", updated_at: "2016-05-13 17:40:42 UTC" },

      # base_path: /government/world-location-news/289211.pt, content_store: live
      # keeping id: 404584, content_id: 7047bbae-8626-4ce5-b810-3f1a999f320f, state: published, updated_at: 2016-05-13 17:40:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702964, content_id: 7047bbae-8626-4ce5-b810-3f1a999f320f, state: published, updated_at: 2016-05-13 17:40:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702964, content_id: "7047bbae-8626-4ce5-b810-3f1a999f320f", updated_at: "2016-05-13 17:40:51 UTC" },

      # base_path: /government/world-location-news/289214.es-419, content_store: live
      # keeping id: 404585, content_id: c235686d-883f-4cb9-9b22-a71edfaa7dea, state: published, updated_at: 2016-05-13 17:40:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702965, content_id: c235686d-883f-4cb9-9b22-a71edfaa7dea, state: published, updated_at: 2016-05-13 17:40:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702965, content_id: "c235686d-883f-4cb9-9b22-a71edfaa7dea", updated_at: "2016-05-13 17:40:51 UTC" },

      # base_path: /government/world-location-news/289218.es-419, content_store: live
      # keeping id: 345924, content_id: 7deb94fa-5271-4817-8f99-8b4d1fb9a284, state: published, updated_at: 2016-05-13 17:40:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702966, content_id: 7deb94fa-5271-4817-8f99-8b4d1fb9a284, state: published, updated_at: 2016-05-13 17:40:51 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702966, content_id: "7deb94fa-5271-4817-8f99-8b4d1fb9a284", updated_at: "2016-05-13 17:40:51 UTC" },

      # base_path: /government/world-location-news/289225.zh-tw, content_store: draft
      # keeping id: 702975, content_id: 44d55be8-dea7-44d5-a852-f6bde078bbd8, state: draft, updated_at: 2016-05-13 17:40:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702974, content_id: 44d55be8-dea7-44d5-a852-f6bde078bbd8, state: draft, updated_at: 2016-05-13 17:40:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702974, content_id: "44d55be8-dea7-44d5-a852-f6bde078bbd8", updated_at: "2016-05-13 17:40:53 UTC" },

      # base_path: /government/world-location-news/289225.zh-tw, content_store: live
      # keeping id: 404586, content_id: 44d55be8-dea7-44d5-a852-f6bde078bbd8, state: published, updated_at: 2016-05-13 17:40:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702967, content_id: 44d55be8-dea7-44d5-a852-f6bde078bbd8, state: published, updated_at: 2016-05-13 17:40:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702967, content_id: "44d55be8-dea7-44d5-a852-f6bde078bbd8", updated_at: "2016-05-13 17:40:52 UTC" },

      # base_path: /government/world-location-news/289226.zh-tw, content_store: draft
      # keeping id: 702970, content_id: 096c2775-7b78-4bc1-ac53-3122f65127fb, state: draft, updated_at: 2016-05-13 17:40:52 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702968, content_id: 096c2775-7b78-4bc1-ac53-3122f65127fb, state: draft, updated_at: 2016-05-13 17:40:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702968, content_id: "096c2775-7b78-4bc1-ac53-3122f65127fb", updated_at: "2016-05-13 17:40:52 UTC" },

      # base_path: /government/world-location-news/289369.fr, content_store: live
      # keeping id: 404587, content_id: cb27aadb-bb6c-44ad-9dd5-cd7d589ae8ab, state: published, updated_at: 2016-05-13 17:41:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 702992, content_id: cb27aadb-bb6c-44ad-9dd5-cd7d589ae8ab, state: published, updated_at: 2016-05-13 17:41:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 702992, content_id: "cb27aadb-bb6c-44ad-9dd5-cd7d589ae8ab", updated_at: "2016-05-13 17:41:06 UTC" },

      # base_path: /government/world-location-news/289534.es-419, content_store: live
      # keeping id: 404588, content_id: f78855db-52bf-4862-99e5-ee53cd58bf41, state: published, updated_at: 2016-05-13 17:41:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703026, content_id: f78855db-52bf-4862-99e5-ee53cd58bf41, state: published, updated_at: 2016-05-13 17:41:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703026, content_id: "f78855db-52bf-4862-99e5-ee53cd58bf41", updated_at: "2016-05-13 17:41:21 UTC" },

      # base_path: /government/world-location-news/289728.cs, content_store: live
      # keeping id: 703064, content_id: 63e081ba-6122-466f-a69e-f81ec56ed01d, state: published, updated_at: 2016-05-13 17:41:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404589, content_id: 63e081ba-6122-466f-a69e-f81ec56ed01d, state: published, updated_at: 2016-05-13 17:41:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404589, content_id: "63e081ba-6122-466f-a69e-f81ec56ed01d", updated_at: "2016-05-13 17:41:43 UTC" },

      # base_path: /government/world-location-news/289930.ro, content_store: draft
      # keeping id: 703102, content_id: d7fbec93-07cb-49ec-bde2-f14bbd99e7d4, state: draft, updated_at: 2016-05-13 17:42:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703100, content_id: d7fbec93-07cb-49ec-bde2-f14bbd99e7d4, state: draft, updated_at: 2016-05-13 17:42:02 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703100, content_id: "d7fbec93-07cb-49ec-bde2-f14bbd99e7d4", updated_at: "2016-05-13 17:42:02 UTC" },

      # base_path: /government/world-location-news/289930.ro, content_store: live
      # keeping id: 345925, content_id: d7fbec93-07cb-49ec-bde2-f14bbd99e7d4, state: published, updated_at: 2016-05-13 17:42:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703097, content_id: d7fbec93-07cb-49ec-bde2-f14bbd99e7d4, state: published, updated_at: 2016-05-13 17:42:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703097, content_id: "d7fbec93-07cb-49ec-bde2-f14bbd99e7d4", updated_at: "2016-05-13 17:42:01 UTC" },

      # base_path: /government/world-location-news/290168.zh-tw, content_store: live
      # keeping id: 345926, content_id: ffc11c75-6c23-4feb-a3e3-a8ddfe6fa601, state: published, updated_at: 2016-05-13 17:42:26 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703136, content_id: ffc11c75-6c23-4feb-a3e3-a8ddfe6fa601, state: published, updated_at: 2016-05-13 17:42:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703136, content_id: "ffc11c75-6c23-4feb-a3e3-a8ddfe6fa601", updated_at: "2016-05-13 17:42:25 UTC" },

      # base_path: /government/world-location-news/290534.pt, content_store: live
      # keeping id: 404590, content_id: e6042fca-557a-43df-bae2-01ad7c2a4b37, state: published, updated_at: 2016-05-13 17:43:02 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703190, content_id: e6042fca-557a-43df-bae2-01ad7c2a4b37, state: published, updated_at: 2016-05-13 17:43:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703190, content_id: "e6042fca-557a-43df-bae2-01ad7c2a4b37", updated_at: "2016-05-13 17:43:01 UTC" },

      # base_path: /government/world-location-news/290702.ja, content_store: live
      # keeping id: 345927, content_id: 5060d150-aa5d-4563-b948-55bdaa859618, state: published, updated_at: 2016-05-13 17:43:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703209, content_id: 5060d150-aa5d-4563-b948-55bdaa859618, state: published, updated_at: 2016-05-13 17:43:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703209, content_id: "5060d150-aa5d-4563-b948-55bdaa859618", updated_at: "2016-05-13 17:43:21 UTC" },

      # base_path: /government/world-location-news/290860.pt, content_store: live
      # keeping id: 286018, content_id: b643132a-5fb4-431e-9dc4-0bfa143da588, state: published, updated_at: 2016-05-13 17:43:37 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703228, content_id: b643132a-5fb4-431e-9dc4-0bfa143da588, state: published, updated_at: 2016-05-13 17:43:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703228, content_id: "b643132a-5fb4-431e-9dc4-0bfa143da588", updated_at: "2016-05-13 17:43:37 UTC" },

      # base_path: /government/world-location-news/291000.es-419, content_store: live
      # keeping id: 286019, content_id: 6b2e4bf4-b61e-4876-af2f-57445bcb871d, state: published, updated_at: 2016-05-13 17:43:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703239, content_id: 6b2e4bf4-b61e-4876-af2f-57445bcb871d, state: published, updated_at: 2016-05-13 17:43:50 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703239, content_id: "6b2e4bf4-b61e-4876-af2f-57445bcb871d", updated_at: "2016-05-13 17:43:50 UTC" },

      # base_path: /government/world-location-news/291036.zh, content_store: live
      # keeping id: 404591, content_id: 41672e7c-a8cf-40e9-a374-f068bc1fc213, state: published, updated_at: 2016-05-13 17:43:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703242, content_id: 41672e7c-a8cf-40e9-a374-f068bc1fc213, state: published, updated_at: 2016-05-13 17:43:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703242, content_id: "41672e7c-a8cf-40e9-a374-f068bc1fc213", updated_at: "2016-05-13 17:43:54 UTC" },

      # base_path: /government/world-location-news/291100.es, content_store: live
      # keeping id: 286020, content_id: 92ea9d04-f1a7-42fd-af51-7405d1a88121, state: published, updated_at: 2016-05-13 17:44:01 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703248, content_id: 92ea9d04-f1a7-42fd-af51-7405d1a88121, state: published, updated_at: 2016-05-13 17:44:01 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703248, content_id: "92ea9d04-f1a7-42fd-af51-7405d1a88121", updated_at: "2016-05-13 17:44:01 UTC" },

      # base_path: /government/world-location-news/291176.pt, content_store: live
      # keeping id: 404592, content_id: 35e3f70f-b5bb-4022-afab-ec09ee9743c2, state: published, updated_at: 2016-05-13 17:44:09 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703254, content_id: 35e3f70f-b5bb-4022-afab-ec09ee9743c2, state: published, updated_at: 2016-05-13 17:44:08 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703254, content_id: "35e3f70f-b5bb-4022-afab-ec09ee9743c2", updated_at: "2016-05-13 17:44:08 UTC" },

      # base_path: /government/world-location-news/291410.es-419, content_store: live
      # keeping id: 286021, content_id: 6f133ae5-36fc-4473-baf3-5c4e23f9fbdb, state: published, updated_at: 2016-05-13 17:44:35 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703283, content_id: 6f133ae5-36fc-4473-baf3-5c4e23f9fbdb, state: published, updated_at: 2016-05-13 17:44:35 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703283, content_id: "6f133ae5-36fc-4473-baf3-5c4e23f9fbdb", updated_at: "2016-05-13 17:44:35 UTC" },

      # base_path: /government/world-location-news/291490.es-419, content_store: live
      # keeping id: 404593, content_id: 6b35817d-809c-4e46-a60c-6f4ca2f09f04, state: published, updated_at: 2016-05-13 17:44:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703308, content_id: 6b35817d-809c-4e46-a60c-6f4ca2f09f04, state: published, updated_at: 2016-05-13 17:44:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703308, content_id: "6b35817d-809c-4e46-a60c-6f4ca2f09f04", updated_at: "2016-05-13 17:44:42 UTC" },

      # base_path: /government/world-location-news/291812.es-419, content_store: live
      # keeping id: 286022, content_id: 708619dd-381a-4115-b65c-35feabc78b30, state: published, updated_at: 2016-05-13 17:45:17 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703344, content_id: 708619dd-381a-4115-b65c-35feabc78b30, state: published, updated_at: 2016-05-13 17:45:16 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703344, content_id: "708619dd-381a-4115-b65c-35feabc78b30", updated_at: "2016-05-13 17:45:16 UTC" },

      # base_path: /government/world-location-news/291857.es-419, content_store: live
      # keeping id: 286023, content_id: 61c402c0-c169-4cb0-bbb3-8b9160942222, state: published, updated_at: 2016-05-13 17:45:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703354, content_id: 61c402c0-c169-4cb0-bbb3-8b9160942222, state: published, updated_at: 2016-05-13 17:45:21 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703354, content_id: "61c402c0-c169-4cb0-bbb3-8b9160942222", updated_at: "2016-05-13 17:45:21 UTC" },

      # base_path: /government/world-location-news/292063.es-419, content_store: live
      # keeping id: 404594, content_id: ab36cd34-f210-485c-9425-0be8e7cd26ff, state: published, updated_at: 2016-05-13 17:45:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703384, content_id: ab36cd34-f210-485c-9425-0be8e7cd26ff, state: published, updated_at: 2016-05-13 17:45:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703384, content_id: "ab36cd34-f210-485c-9425-0be8e7cd26ff", updated_at: "2016-05-13 17:45:41 UTC" },

      # base_path: /government/world-location-news/292182.el, content_store: live
      # keeping id: 703394, content_id: 1deb3e7e-da70-4158-b5e5-b7143c50d369, state: published, updated_at: 2016-05-13 17:45:54 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404596, content_id: 1deb3e7e-da70-4158-b5e5-b7143c50d369, state: published, updated_at: 2016-05-13 17:45:53 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404596, content_id: "1deb3e7e-da70-4158-b5e5-b7143c50d369", updated_at: "2016-05-13 17:45:53 UTC" },

      # base_path: /government/world-location-news/292788.zh-tw, content_store: live
      # keeping id: 404597, content_id: 971d38c9-2abc-48e8-86ed-7475d5d1a943, state: published, updated_at: 2016-05-13 17:46:59 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703476, content_id: 971d38c9-2abc-48e8-86ed-7475d5d1a943, state: published, updated_at: 2016-05-13 17:46:58 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703476, content_id: "971d38c9-2abc-48e8-86ed-7475d5d1a943", updated_at: "2016-05-13 17:46:58 UTC" },

      # base_path: /government/world-location-news/292871.es-419, content_store: live
      # keeping id: 345928, content_id: bdc0e241-5559-4cbd-b32a-beb090bdd2d3, state: published, updated_at: 2016-05-13 17:47:07 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703491, content_id: bdc0e241-5559-4cbd-b32a-beb090bdd2d3, state: published, updated_at: 2016-05-13 17:47:06 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703491, content_id: "bdc0e241-5559-4cbd-b32a-beb090bdd2d3", updated_at: "2016-05-13 17:47:06 UTC" },

      # base_path: /government/world-location-news/292905.de, content_store: live
      # keeping id: 703498, content_id: 8585d19e-e80c-4c97-9435-2f264e60bdf7, state: published, updated_at: 2016-05-13 17:47:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 286024, content_id: 8585d19e-e80c-4c97-9435-2f264e60bdf7, state: published, updated_at: 2016-05-13 17:47:09 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 286024, content_id: "8585d19e-e80c-4c97-9435-2f264e60bdf7", updated_at: "2016-05-13 17:47:09 UTC" },

      # base_path: /government/world-location-news/292953.es, content_store: draft
      # keeping id: 703507, content_id: 1b912fbb-ad86-41b1-be15-348245d38847, state: draft, updated_at: 2016-05-13 17:47:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703506, content_id: 1b912fbb-ad86-41b1-be15-348245d38847, state: draft, updated_at: 2016-05-13 17:47:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703506, content_id: "1b912fbb-ad86-41b1-be15-348245d38847", updated_at: "2016-05-13 17:47:15 UTC" },

      # base_path: /government/world-location-news/292953.es, content_store: live
      # keeping id: 345929, content_id: 1b912fbb-ad86-41b1-be15-348245d38847, state: published, updated_at: 2016-05-13 17:47:14 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703504, content_id: 1b912fbb-ad86-41b1-be15-348245d38847, state: published, updated_at: 2016-05-13 17:47:13 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703504, content_id: "1b912fbb-ad86-41b1-be15-348245d38847", updated_at: "2016-05-13 17:47:13 UTC" },

      # base_path: /government/world-location-news/293194.es-419, content_store: draft
      # keeping id: 703546, content_id: 1a2a4cec-c47a-473e-9359-8dcd3f661acd, state: draft, updated_at: 2016-05-13 17:47:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703545, content_id: 1a2a4cec-c47a-473e-9359-8dcd3f661acd, state: draft, updated_at: 2016-05-13 17:47:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703545, content_id: "1a2a4cec-c47a-473e-9359-8dcd3f661acd", updated_at: "2016-05-13 17:47:39 UTC" },

      # base_path: /government/world-location-news/293194.es-419, content_store: live
      # keeping id: 345930, content_id: 1a2a4cec-c47a-473e-9359-8dcd3f661acd, state: published, updated_at: 2016-05-13 17:47:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703542, content_id: 1a2a4cec-c47a-473e-9359-8dcd3f661acd, state: published, updated_at: 2016-05-13 17:47:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703542, content_id: "1a2a4cec-c47a-473e-9359-8dcd3f661acd", updated_at: "2016-05-13 17:47:38 UTC" },

      # base_path: /government/world-location-news/293342.ja, content_store: live
      # keeping id: 345931, content_id: 6839ed38-6b12-453b-b58b-1f0187bdfabd, state: published, updated_at: 2016-05-13 17:47:50 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703565, content_id: 6839ed38-6b12-453b-b58b-1f0187bdfabd, state: published, updated_at: 2016-05-13 17:47:49 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703565, content_id: "6839ed38-6b12-453b-b58b-1f0187bdfabd", updated_at: "2016-05-13 17:47:49 UTC" },

      # base_path: /government/world-location-news/293476.es, content_store: live
      # keeping id: 404598, content_id: 69e05b97-d10d-4914-9db2-08c1b1559d50, state: published, updated_at: 2016-05-13 17:48:04 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703580, content_id: 69e05b97-d10d-4914-9db2-08c1b1559d50, state: published, updated_at: 2016-05-13 17:48:03 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703580, content_id: "69e05b97-d10d-4914-9db2-08c1b1559d50", updated_at: "2016-05-13 17:48:03 UTC" },

      # base_path: /government/world-location-news/293828.es-419, content_store: draft
      # keeping id: 703647, content_id: 3879cfd1-ea94-4e02-b1d9-62358d1ace84, state: draft, updated_at: 2016-05-13 17:48:39 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703646, content_id: 3879cfd1-ea94-4e02-b1d9-62358d1ace84, state: draft, updated_at: 2016-05-13 17:48:39 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703646, content_id: "3879cfd1-ea94-4e02-b1d9-62358d1ace84", updated_at: "2016-05-13 17:48:39 UTC" },

      # base_path: /government/world-location-news/293828.es-419, content_store: live
      # keeping id: 286025, content_id: 3879cfd1-ea94-4e02-b1d9-62358d1ace84, state: published, updated_at: 2016-05-13 17:48:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703645, content_id: 3879cfd1-ea94-4e02-b1d9-62358d1ace84, state: published, updated_at: 2016-05-13 17:48:38 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703645, content_id: "3879cfd1-ea94-4e02-b1d9-62358d1ace84", updated_at: "2016-05-13 17:48:38 UTC" },

      # base_path: /government/world-location-news/293929.es-419, content_store: draft
      # keeping id: 703665, content_id: 27cc9bb4-fa91-4c9d-8e3c-e94ef25b44d4, state: draft, updated_at: 2016-05-13 17:48:51 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703661, content_id: 27cc9bb4-fa91-4c9d-8e3c-e94ef25b44d4, state: draft, updated_at: 2016-05-13 17:48:48 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703661, content_id: "27cc9bb4-fa91-4c9d-8e3c-e94ef25b44d4", updated_at: "2016-05-13 17:48:48 UTC" },

      # base_path: /government/world-location-news/294043.es-419, content_store: live
      # keeping id: 286026, content_id: a8238512-61e8-4704-babb-07f686351299, state: published, updated_at: 2016-05-13 17:49:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703680, content_id: a8238512-61e8-4704-babb-07f686351299, state: published, updated_at: 2016-05-13 17:49:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703680, content_id: "a8238512-61e8-4704-babb-07f686351299", updated_at: "2016-05-13 17:49:00 UTC" },

      # base_path: /government/world-location-news/294046.es-419, content_store: draft
      # keeping id: 703682, content_id: 970fbd99-8a2a-4e6c-9386-85a37e76c9f5, state: draft, updated_at: 2016-05-13 17:49:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703681, content_id: 970fbd99-8a2a-4e6c-9386-85a37e76c9f5, state: draft, updated_at: 2016-05-13 17:49:00 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703681, content_id: "970fbd99-8a2a-4e6c-9386-85a37e76c9f5", updated_at: "2016-05-13 17:49:00 UTC" },

      # base_path: /government/world-location-news/294159.es-419, content_store: live
      # keeping id: 404599, content_id: 316fdcc3-549c-415d-b007-f8479f9d226c, state: published, updated_at: 2016-05-13 17:49:12 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703692, content_id: 316fdcc3-549c-415d-b007-f8479f9d226c, state: published, updated_at: 2016-05-13 17:49:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703692, content_id: "316fdcc3-549c-415d-b007-f8479f9d226c", updated_at: "2016-05-13 17:49:12 UTC" },

      # base_path: /government/world-location-news/294171.es-419, content_store: live
      # keeping id: 404600, content_id: 286b7d43-c312-4400-9e45-f593f3b7c7cb, state: published, updated_at: 2016-05-13 17:49:13 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703694, content_id: 286b7d43-c312-4400-9e45-f593f3b7c7cb, state: published, updated_at: 2016-05-13 17:49:12 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703694, content_id: "286b7d43-c312-4400-9e45-f593f3b7c7cb", updated_at: "2016-05-13 17:49:12 UTC" },

      # base_path: /government/world-location-news/294250.de, content_store: draft
      # keeping id: 703710, content_id: 3d964a31-2960-465c-91cf-9471d301e563, state: draft, updated_at: 2016-05-13 17:49:22 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703709, content_id: 3d964a31-2960-465c-91cf-9471d301e563, state: draft, updated_at: 2016-05-13 17:49:22 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703709, content_id: "3d964a31-2960-465c-91cf-9471d301e563", updated_at: "2016-05-13 17:49:22 UTC" },

      # base_path: /government/world-location-news/294250.de, content_store: live
      # keeping id: 703708, content_id: 3d964a31-2960-465c-91cf-9471d301e563, state: published, updated_at: 2016-05-13 17:49:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404601, content_id: 3d964a31-2960-465c-91cf-9471d301e563, state: published, updated_at: 2016-05-13 17:49:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404601, content_id: "3d964a31-2960-465c-91cf-9471d301e563", updated_at: "2016-05-13 17:49:20 UTC" },

      # base_path: /government/world-location-news/294447.pt, content_store: live
      # keeping id: 703737, content_id: 53646529-484f-4899-9932-cccab11027b4, state: published, updated_at: 2016-05-13 17:49:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345932, content_id: 53646529-484f-4899-9932-cccab11027b4, state: published, updated_at: 2016-05-13 17:49:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345932, content_id: "53646529-484f-4899-9932-cccab11027b4", updated_at: "2016-05-13 17:49:40 UTC" },

      # base_path: /government/world-location-news/294453.pt, content_store: live
      # keeping id: 286027, content_id: 030c6ca5-ff0c-4305-9ad3-6b7052a3cf16, state: published, updated_at: 2016-05-13 17:49:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703736, content_id: 030c6ca5-ff0c-4305-9ad3-6b7052a3cf16, state: published, updated_at: 2016-05-13 17:49:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703736, content_id: "030c6ca5-ff0c-4305-9ad3-6b7052a3cf16", updated_at: "2016-05-13 17:49:41 UTC" },

      # base_path: /government/world-location-news/294579.pt, content_store: live
      # keeping id: 345933, content_id: 620c7499-3f50-4243-8641-456d45ff5ce7, state: published, updated_at: 2016-05-13 17:49:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703750, content_id: 620c7499-3f50-4243-8641-456d45ff5ce7, state: published, updated_at: 2016-05-13 17:49:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703750, content_id: "620c7499-3f50-4243-8641-456d45ff5ce7", updated_at: "2016-05-13 17:49:52 UTC" },

      # base_path: /government/world-location-news/294626.zh-tw, content_store: live
      # keeping id: 404602, content_id: 7e455d64-1084-41ec-b98f-2535e62a1a52, state: published, updated_at: 2016-05-13 17:49:57 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703754, content_id: 7e455d64-1084-41ec-b98f-2535e62a1a52, state: published, updated_at: 2016-05-13 17:49:57 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703754, content_id: "7e455d64-1084-41ec-b98f-2535e62a1a52", updated_at: "2016-05-13 17:49:57 UTC" },

      # base_path: /government/world-location-news/294647.de, content_store: live
      # keeping id: 703757, content_id: 04ddc900-2de1-4064-8de9-9018ddeab396, state: published, updated_at: 2016-05-13 17:50:00 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404603, content_id: 04ddc900-2de1-4064-8de9-9018ddeab396, state: published, updated_at: 2016-05-13 17:49:59 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404603, content_id: "04ddc900-2de1-4064-8de9-9018ddeab396", updated_at: "2016-05-13 17:49:59 UTC" },

      # base_path: /government/world-location-news/294701.pt, content_store: live
      # keeping id: 286028, content_id: af46fab1-eacc-4813-b5bf-c7c78395d298, state: published, updated_at: 2016-05-13 17:50:06 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703766, content_id: af46fab1-eacc-4813-b5bf-c7c78395d298, state: published, updated_at: 2016-05-13 17:50:05 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703766, content_id: "af46fab1-eacc-4813-b5bf-c7c78395d298", updated_at: "2016-05-13 17:50:05 UTC" },

      # base_path: /government/world-location-news/295021.ja, content_store: live
      # keeping id: 345934, content_id: fa576b59-b7df-4e4f-95f7-6ddbc32d3b47, state: published, updated_at: 2016-05-13 17:50:38 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703829, content_id: fa576b59-b7df-4e4f-95f7-6ddbc32d3b47, state: published, updated_at: 2016-05-13 17:50:37 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703829, content_id: "fa576b59-b7df-4e4f-95f7-6ddbc32d3b47", updated_at: "2016-05-13 17:50:37 UTC" },

      # base_path: /government/world-location-news/295391.es-419, content_store: live
      # keeping id: 404604, content_id: 2a8c5de9-ec3f-48d8-add8-f8b5aa39f2f8, state: published, updated_at: 2016-05-13 17:51:15 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703886, content_id: 2a8c5de9-ec3f-48d8-add8-f8b5aa39f2f8, state: published, updated_at: 2016-05-13 17:51:14 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703886, content_id: "2a8c5de9-ec3f-48d8-add8-f8b5aa39f2f8", updated_at: "2016-05-13 17:51:14 UTC" },

      # base_path: /government/world-location-news/295550.es-419, content_store: live
      # keeping id: 345935, content_id: 20a31d64-5803-4f74-abc3-143130f6b3fc, state: published, updated_at: 2016-05-13 17:51:31 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703909, content_id: 20a31d64-5803-4f74-abc3-143130f6b3fc, state: published, updated_at: 2016-05-13 17:51:30 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703909, content_id: "20a31d64-5803-4f74-abc3-143130f6b3fc", updated_at: "2016-05-13 17:51:30 UTC" },

      # base_path: /government/world-location-news/295678.pt, content_store: live
      # keeping id: 404605, content_id: 4135c428-0fb9-4e17-9224-c9d2e64608b4, state: published, updated_at: 2016-05-13 17:51:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703925, content_id: 4135c428-0fb9-4e17-9224-c9d2e64608b4, state: published, updated_at: 2016-05-13 17:51:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703925, content_id: "4135c428-0fb9-4e17-9224-c9d2e64608b4", updated_at: "2016-05-13 17:51:44 UTC" },

      # base_path: /government/world-location-news/295683.pt, content_store: live
      # keeping id: 404606, content_id: c3ecd8f8-80ca-45e6-85fc-76696ee5b8db, state: published, updated_at: 2016-05-13 17:51:45 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703927, content_id: c3ecd8f8-80ca-45e6-85fc-76696ee5b8db, state: published, updated_at: 2016-05-13 17:51:44 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703927, content_id: "c3ecd8f8-80ca-45e6-85fc-76696ee5b8db", updated_at: "2016-05-13 17:51:44 UTC" },

      # base_path: /government/world-location-news/295713.ar, content_store: draft
      # keeping id: 703933, content_id: 3c52b40c-f2e8-4034-b3fe-37f2e65d4bb5, state: draft, updated_at: 2016-05-13 17:51:47 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703932, content_id: 3c52b40c-f2e8-4034-b3fe-37f2e65d4bb5, state: draft, updated_at: 2016-05-13 17:51:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703932, content_id: "3c52b40c-f2e8-4034-b3fe-37f2e65d4bb5", updated_at: "2016-05-13 17:51:47 UTC" },

      # base_path: /government/world-location-news/296094.es, content_store: live
      # keeping id: 404607, content_id: b1983e61-65a0-44b4-9a22-687163c86ebd, state: published, updated_at: 2016-05-13 17:52:25 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703977, content_id: b1983e61-65a0-44b4-9a22-687163c86ebd, state: published, updated_at: 2016-05-13 17:52:25 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703977, content_id: "b1983e61-65a0-44b4-9a22-687163c86ebd", updated_at: "2016-05-13 17:52:25 UTC" },

      # base_path: /government/world-location-news/296261.es-419, content_store: draft
      # keeping id: 703992, content_id: 4044a274-0cf5-40bc-a3a0-dc6dda407e6d, state: draft, updated_at: 2016-05-13 17:52:41 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703991, content_id: 4044a274-0cf5-40bc-a3a0-dc6dda407e6d, state: draft, updated_at: 2016-05-13 17:52:41 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703991, content_id: "4044a274-0cf5-40bc-a3a0-dc6dda407e6d", updated_at: "2016-05-13 17:52:41 UTC" },

      # base_path: /government/world-location-news/296261.es-419, content_store: live
      # keeping id: 345936, content_id: 4044a274-0cf5-40bc-a3a0-dc6dda407e6d, state: published, updated_at: 2016-05-13 17:52:40 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 703989, content_id: 4044a274-0cf5-40bc-a3a0-dc6dda407e6d, state: published, updated_at: 2016-05-13 17:52:40 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 703989, content_id: "4044a274-0cf5-40bc-a3a0-dc6dda407e6d", updated_at: "2016-05-13 17:52:40 UTC" },

      # base_path: /government/world-location-news/296412.el, content_store: live
      # keeping id: 704014, content_id: 93a07b28-dd4a-42a4-a4cf-14506a6d10a4, state: published, updated_at: 2016-05-13 17:52:55 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404608, content_id: 93a07b28-dd4a-42a4-a4cf-14506a6d10a4, state: published, updated_at: 2016-05-13 17:52:54 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404608, content_id: "93a07b28-dd4a-42a4-a4cf-14506a6d10a4", updated_at: "2016-05-13 17:52:54 UTC" },

      # base_path: /government/world-location-news/296578.es-419, content_store: live
      # keeping id: 345937, content_id: ec489d9a-961a-41bd-b16f-49aa8a8e01ca, state: published, updated_at: 2016-05-13 17:53:10 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 704040, content_id: ec489d9a-961a-41bd-b16f-49aa8a8e01ca, state: published, updated_at: 2016-05-13 17:53:10 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 704040, content_id: "ec489d9a-961a-41bd-b16f-49aa8a8e01ca", updated_at: "2016-05-13 17:53:10 UTC" },

      # base_path: /government/world-location-news/296916.pt, content_store: live
      # keeping id: 404609, content_id: 0879ce52-b803-47f1-92c4-d260305b7607, state: published, updated_at: 2016-05-13 17:53:42 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 704092, content_id: 0879ce52-b803-47f1-92c4-d260305b7607, state: published, updated_at: 2016-05-13 17:53:42 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 704092, content_id: "0879ce52-b803-47f1-92c4-d260305b7607", updated_at: "2016-05-13 17:53:42 UTC" },

      # base_path: /government/world-location-news/296924.pt, content_store: live
      # keeping id: 404610, content_id: 92f3e3d1-9921-4f9a-8621-9639eff5e1c8, state: published, updated_at: 2016-05-13 17:53:43 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 704093, content_id: 92f3e3d1-9921-4f9a-8621-9639eff5e1c8, state: published, updated_at: 2016-05-13 17:53:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 704093, content_id: "92f3e3d1-9921-4f9a-8621-9639eff5e1c8", updated_at: "2016-05-13 17:53:43 UTC" },

      # base_path: /government/world-location-news/296925.pt, content_store: live
      # keeping id: 704094, content_id: fae1d718-db63-4377-abeb-b7ec43d3af38, state: published, updated_at: 2016-05-13 17:53:44 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 238112, content_id: fae1d718-db63-4377-abeb-b7ec43d3af38, state: published, updated_at: 2016-05-13 17:53:43 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 238112, content_id: "fae1d718-db63-4377-abeb-b7ec43d3af38", updated_at: "2016-05-13 17:53:43 UTC" },

      # base_path: /government/world-location-news/296968.zh-tw, content_store: live
      # keeping id: 404579, content_id: 2d7a31f8-5702-410d-8af6-edc0927ac9dc, state: published, updated_at: 2016-05-13 17:53:47 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 704101, content_id: 2d7a31f8-5702-410d-8af6-edc0927ac9dc, state: published, updated_at: 2016-05-13 17:53:47 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 704101, content_id: "2d7a31f8-5702-410d-8af6-edc0927ac9dc", updated_at: "2016-05-13 17:53:47 UTC" },

      # base_path: /government/world-location-news/297168.cs, content_store: live
      # keeping id: 704140, content_id: 50c1457b-0699-44ff-970b-56a107dcb016, state: published, updated_at: 2016-05-13 17:54:08 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345938, content_id: 50c1457b-0699-44ff-970b-56a107dcb016, state: published, updated_at: 2016-05-13 17:54:07 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345938, content_id: "50c1457b-0699-44ff-970b-56a107dcb016", updated_at: "2016-05-13 17:54:07 UTC" },

      # base_path: /government/world-location-news/297272.ar, content_store: live
      # keeping id: 704157, content_id: 833e7044-0b80-41db-a514-b903ec1a143a, state: published, updated_at: 2016-05-13 17:54:16 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 345939, content_id: 833e7044-0b80-41db-a514-b903ec1a143a, state: published, updated_at: 2016-05-13 17:54:15 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 345939, content_id: "833e7044-0b80-41db-a514-b903ec1a143a", updated_at: "2016-05-13 17:54:15 UTC" },

      # base_path: /government/world-location-news/297307.bg, content_store: live
      # keeping id: 704165, content_id: d2383626-6ff0-4cea-b0d8-14f1b0d11366, state: published, updated_at: 2016-05-13 17:54:20 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404595, content_id: d2383626-6ff0-4cea-b0d8-14f1b0d11366, state: published, updated_at: 2016-05-13 17:54:19 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404595, content_id: "d2383626-6ff0-4cea-b0d8-14f1b0d11366", updated_at: "2016-05-13 17:54:19 UTC" },

      # base_path: /government/world-location-news/297697.cs, content_store: live
      # keeping id: 704218, content_id: 027f4907-21b0-41f0-ac2f-2a92fa3d3c11, state: published, updated_at: 2016-05-13 17:54:53 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404611, content_id: 027f4907-21b0-41f0-ac2f-2a92fa3d3c11, state: published, updated_at: 2016-05-13 17:54:52 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404611, content_id: "027f4907-21b0-41f0-ac2f-2a92fa3d3c11", updated_at: "2016-05-13 17:54:52 UTC" },

      # base_path: /government/world-location-news/297977.pt, content_store: live
      # keeping id: 704250, content_id: ef2093c5-2628-4b7d-834d-0deb52c5dcda, state: published, updated_at: 2016-05-13 17:55:21 UTC, publishing_app: whitehall, document_type: news_article
      # deleting id: 404612, content_id: ef2093c5-2628-4b7d-834d-0deb52c5dcda, state: published, updated_at: 2016-05-13 17:55:20 UTC, publishing_app: whitehall, document_type: news_article, details match item to keep: yes
      { id: 404612, content_id: "ef2093c5-2628-4b7d-834d-0deb52c5dcda", updated_at: "2016-05-13 17:55:20 UTC" },

      # base_path: /government/world/organisations/british-embassy-venezuela/about/recruitment, content_store: live
      # keeping id: 752707, content_id: 5f5520b3-7631-11e4-a3cb-005056011aef, state: published, updated_at: 2016-05-26 14:25:54 UTC, publishing_app: whitehall, document_type: recruitment
      # deleting id: 681308, content_id: 0cfe1025-bdea-489f-a5eb-2f1e762e0ac0, state: published, updated_at: 2016-05-13 13:04:39 UTC, publishing_app: whitehall, document_type: redirect, details match item to keep: no
      { id: 681308, content_id: "0cfe1025-bdea-489f-a5eb-2f1e762e0ac0", updated_at: "2016-05-13 13:04:39 UTC" },

      # base_path: /international-development-funding/building-resilience-and-adaptation-to-climate-extremes-and-disasters-programme, content_store: live
      # keeping id: 973019, content_id: 5c1f5fd5-2c22-4df1-9b72-0a80a9b6cec5, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-09 13:29:23 UTC, publishing_app: specialist-publisher, document_type: international_development_fund
      # deleting id: 26965, content_id: 48554cd7-f325-4e7d-ada1-a9af52206c25, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 26965, content_id: "48554cd7-f325-4e7d-ada1-a9af52206c25", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /international-development-funding/ethiopian-competitiveness-facility, content_store: live
      # keeping id: 973024, content_id: 049bc19d-428f-4201-bb37-7661cfb192fc, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-09 13:29:24 UTC, publishing_app: specialist-publisher, document_type: international_development_fund
      # deleting id: 26974, content_id: 58d3d403-e093-405e-ad3d-b0cb733e29c3, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 26974, content_id: "58d3d403-e093-405e-ad3d-b0cb733e29c3", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /international-development-funding/ghana-research-advocacy-programme, content_store: live
      # keeping id: 973017, content_id: 021208fc-c4dc-45a4-b750-bcf6211276ee, state: unpublished, unpublishing_type: gone, updated_at: 2016-08-09 13:29:23 UTC, publishing_app: specialist-publisher, document_type: international_development_fund
      # deleting id: 134882, content_id: 7818ae95-6407-4786-970a-1d1de98585e6, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 134882, content_id: "7818ae95-6407-4786-970a-1d1de98585e6", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /investment-for-growth-north-east, content_store: draft
      # keeping id: 667316, content_id: c8d9daa3-6e3a-4422-bde4-b85b7a54c526, state: draft, updated_at: 2016-05-06 14:08:15 UTC, publishing_app: publisher, document_type: placeholder
      # deleting id: 36282, content_id: 4032908f-511e-408e-86b0-696088cc5b15, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: publisher, document_type: placeholder, details match item to keep: no
      { id: 36282, content_id: "4032908f-511e-408e-86b0-696088cc5b15", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 251342, content_id: 4032908f-511e-408e-86b0-696088cc5b15, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: publisher, document_type: placeholder, details match item to keep: no
      { id: 251342, content_id: "4032908f-511e-408e-86b0-696088cc5b15", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /maib-reports/fire-on-board-ropax-ferry-dieppe-seaways, content_store: live
      # keeping id: 866939, content_id: c92e4e5d-29b1-45d7-9fea-70b989e05c69, state: unpublished, unpublishing_type: gone, updated_at: 2016-07-25 11:33:26 UTC, publishing_app: specialist-publisher, document_type: maib_report
      # deleting id: 27315, content_id: 44e58ce1-9a08-410d-bf48-b37a087dc830, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 27315, content_id: "44e58ce1-9a08-410d-bf48-b37a087dc830", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /maib-reports/flooding-and-abandonment-of-general-cargo-vessel-sea-breeze, content_store: live
      # keeping id: 866949, content_id: cc699820-129e-4f94-896d-2c245f1fa28d, state: unpublished, unpublishing_type: gone, updated_at: 2016-07-25 11:33:27 UTC, publishing_app: specialist-publisher, document_type: maib_report
      # deleting id: 36460, content_id: b4b8b88a-0577-4e61-bc5a-2c1d96f9506a, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 36460, content_id: "b4b8b88a-0577-4e61-bc5a-2c1d96f9506a", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /maib-reports/grounding-and-flooding-of-the-ro-ro-ferry-commodore-clipper, content_store: live
      # keeping id: 866943, content_id: 7fbc3afe-35c5-45a6-9f5b-cec4818a81af, state: unpublished, unpublishing_type: gone, updated_at: 2016-07-25 11:33:26 UTC, publishing_app: specialist-publisher, document_type: maib_report
      # deleting id: 36463, content_id: 242e87f9-e296-42cf-8937-e3300917c003, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 36463, content_id: "242e87f9-e296-42cf-8937-e3300917c003", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /maib-reports/two-separate-fatalities-connected-with-the-operation-of-workboat-gps-battler, content_store: live
      # keeping id: 866945, content_id: f18c1bfd-b5d7-4f61-9edb-e0c5881f24bd, state: unpublished, unpublishing_type: gone, updated_at: 2016-07-25 11:33:26 UTC, publishing_app: specialist-publisher, document_type: maib_report
      # deleting id: 36478, content_id: e4bb418e-b126-4c8d-9a84-9bb715828eb9, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: specialist-publisher, document_type: gone, details match item to keep: no
      { id: 36478, content_id: "e4bb418e-b126-4c8d-9a84-9bb715828eb9", updated_at: "2016-02-29 09:24:10 UTC" },

      # base_path: /service-manual/technology, content_store: draft
      # keeping id: 998639, content_id: c0f55d25-e6f6-4a7b-9142-0be5e07b734e, state: draft, updated_at: 2016-08-24 12:52:09 UTC, publishing_app: service-manual-publisher, document_type: service_manual_topic
      # deleting id: 733483, content_id: 0dbdff37-0fe3-4c43-8ebc-92965a52bc87, state: draft, updated_at: 2016-05-23 12:57:30 UTC, publishing_app: service-manual-publisher, document_type: service_manual_topic, details match item to keep: no
      { id: 733483, content_id: "0dbdff37-0fe3-4c43-8ebc-92965a52bc87", updated_at: "2016-05-23 12:57:30 UTC" },

      # base_path: /spirit-enterprise-fund-north-east-england, content_store: draft
      # keeping id: 667321, content_id: 41d78758-1ecd-401e-99d3-2325982a6da7, state: draft, updated_at: 2016-05-06 14:08:17 UTC, publishing_app: publisher, document_type: placeholder
      # deleting id: 37530, content_id: c48d1d7c-6faf-404d-b8d3-6784639d36ac, state: published, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: publisher, document_type: placeholder, details match item to keep: no
      { id: 37530, content_id: "c48d1d7c-6faf-404d-b8d3-6784639d36ac", updated_at: "2016-02-29 09:24:10 UTC" },
      # deleting id: 252763, content_id: c48d1d7c-6faf-404d-b8d3-6784639d36ac, state: draft, updated_at: 2016-02-29 09:24:10 UTC, publishing_app: publisher, document_type: placeholder, details match item to keep: no
      { id: 252763, content_id: "c48d1d7c-6faf-404d-b8d3-6784639d36ac", updated_at: "2016-02-29 09:24:10 UTC" },
    ]
  end
end
