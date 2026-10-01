RSpec.describe "migrate_publisher_dbt_docs_to_dbist rake task" do
  let(:task) { Rake::Task["migrate_publisher_dbt_docs_to_dbist"] }
  let(:dbt_content_id) { "aa750cdf-7925-429d-a2b3-0d9fa47d2c48" }
  let(:dbist_content_id) { "d62ba2be-4ae5-4a9c-ac19-7c1dd197deea" }
  let(:other_org_content_id) { SecureRandom.uuid }

  before do
    task.reenable
    stub_request(:put, %r{.*content-store.*/content/.*})
    allow($stdout).to receive(:puts)
    create(:link, target_content_id: dbist_content_id)
  end

  def organisation_links_for(content_id)
    LinkSet.find_by(content_id:).links.where(link_type: "organisations").pluck(:target_content_id)
  end

  it "replaces DBT with DBIST, keeping other organisations" do
    edition = create(:live_edition, publishing_app: "publisher")
    create(:link_set, content_id: edition.content_id, links_hash: { organisations: [other_org_content_id, dbt_content_id] })

    task.invoke

    expect(organisation_links_for(edition.content_id)).to eq([other_org_content_id, dbist_content_id])
  end

  it "migrates draft editions" do
    edition = create(:draft_edition, publishing_app: "publisher")
    create(:link_set, content_id: edition.content_id, links_hash: { organisations: [dbt_content_id] })

    task.invoke

    expect(organisation_links_for(edition.content_id)).to eq([dbist_content_id])
  end

  it "does not touch other link types" do
    edition = create(:live_edition, publishing_app: "publisher")
    create(
      :link_set,
      content_id: edition.content_id,
      links_hash: {
        organisations: [dbt_content_id],
        primary_publishing_organisation: [dbt_content_id],
      },
    )

    task.invoke

    link_set = LinkSet.find_by(content_id: edition.content_id)
    expect(link_set.links.where(link_type: "primary_publishing_organisation").pluck(:target_content_id))
      .to eq([dbt_content_id])
  end

  it "does not duplicate DBIST when the document is already tagged to it" do
    edition = create(:live_edition, publishing_app: "publisher")
    create(:link_set, content_id: edition.content_id, links_hash: { organisations: [dbist_content_id, dbt_content_id] })

    task.invoke

    expect(organisation_links_for(edition.content_id)).to eq([dbist_content_id])
  end

  it "ignores documents from other publishing apps" do
    edition = create(:live_edition, publishing_app: "whitehall")
    create(:link_set, content_id: edition.content_id, links_hash: { organisations: [dbt_content_id] })

    task.invoke

    expect(organisation_links_for(edition.content_id)).to eq([dbt_content_id])
  end

  it "ignores documents not tagged to DBT" do
    edition = create(:live_edition, publishing_app: "publisher")
    create(:link_set, content_id: edition.content_id, links_hash: { organisations: [other_org_content_id] })

    expect(Commands::V2::PatchLinkSet).not_to receive(:call)

    task.invoke
  end
end
