class RemoveSpecialistDocumentFinderLinks < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  DOCUMENT_TYPE_CONTENT_IDS = {
    aaib_report: "b7574bba-969f-4c49-855a-ae1586258ff6",
    asylum_support_decision: "581b4bba-e58f-4d07-8e0a-03c8c00165cc",
    business_finance_support_scheme: "12fecc5b-c02a-405e-b96e-7aa32ceaf504",
    cma_case: "fef4ac7c-024a-4943-9f19-e85a8369a1f3",
    countryside_stewardship_grant: "0eb7b150-879a-4c44-becc-718e23a77e2c",
    dfid_research_output: "af7c7cdb-1335-4f1c-b21c-b3c8bfec8a1b",
    drug_safety_update: "602be505-4cf4-4f8c-8bfc-7bc4b63a7f47",
    employment_appeal_tribunal_decision: "975cf540-6e64-40e3-b62a-df655a8c99ef",
    employment_tribunal_decision: "1b5e08c8-ddde-4637-9375-f79e085ba6d5",
    esi_fund: "78cedbfe-d3aa-41c3-b8c0-aeb5d9035d6a",
    international_development_fund: "5583057c-7c57-4cfe-b70d-dad6f4762831",
    maib_report: "33eb214a-9291-49d3-8789-445c1e97b586",
    medical_safety_alert: "1e9c0ada-5f7e-43cc-a55f-cc32757edaa3",
    raib_report: "e3ff7fc5-6788-45de-83f0-cbf34e9fe8bd",
    service_standard_report: "da025a9f-8293-4fef-869c-12445d364696",
    tax_tribunal_decision: "632290ae-aad8-4895-b135-1e0a72a6bdeb",
    utaac_decision: "e9e7fcff-bb0d-4723-af25-9f78d730f6f8",
    vehicle_recalls_and_faults_alert: "76290530-743e-4a8c-8752-04ebee25f64a",
  }.freeze

  def up
    delete_links

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.(content_ids_to_represent)
    end
  end

  def delete_links
    Link
      .joins(:link_set)
      .joins("INNER JOIN documents ON link_sets.content_id = documents.content_id")
      .joins("INNER JOIN editions ON documents.id = editions.document_id")
      .where(
        link_type: "parent",
        "editions.publishing_app": "specialist-publisher",
        "editions.document_type": DOCUMENT_TYPE_CONTENT_IDS.keys,
      )
      .delete_all
  end

  def content_ids_to_represent
    edition_ids = Edition
      .with_document
      .where(
        publishing_app: "specialist-publisher",
        document_type: DOCUMENT_TYPE_CONTENT_IDS.keys,
      )
      .where.not(content_store: nil)
      .distinct
      .pluck(:content_id)

    (edition_ids + DOCUMENT_TYPE_CONTENT_IDS.values).uniq
  end
end
