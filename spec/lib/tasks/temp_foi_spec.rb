RSpec.describe "Temporary FOI rake tasks" do
  describe "temp_foi" do
    let(:task) { Rake::Task["temp_foi"] }
    before do
      task.reenable

      ministerial_role_1 = create(:live_edition, schema_name: "role", document_type: "ministerial_role")
      ministerial_role_2 = create(:live_edition, schema_name: "role", document_type: "ministerial_role")
      non_ministerial_role = create(:live_edition, schema_name: "role", document_type: "chief_scientific_officer_role")

      create(:live_edition,
             published_at: "2021-12-31 01:00",
             schema_name: "role_appointment",
             content_store: "live",
             title: "MP 1 - Secretary of State",
             details: {
               started_on: "2021-12-30 00:00",
               ended_on: nil,
               current: true,
             },
             links_hash: {
               role: [
                 ministerial_role_1.content_id,
               ],
             })

      create(:live_edition,
             published_at: "2022-01-01 01:00",
             schema_name: "role_appointment",
             content_store: "live",
             title: "MP 2 - Parliamentary Under Secretary of State",
             details: {
               started_on: "2022-01-01 00:00",
               ended_on: nil,
               current: true,
             },
             links_hash: {
               role: [
                 ministerial_role_2.content_id,
               ],
             })

      create(:live_edition,
             published_at: "2022-01-04 01:00",
             schema_name: "role_appointment",
             content_store: "live",
             title: "Not an MP 1 - Chief Scientific Officer",
             details: {
               started_on: "2021-12-30 00:00",
               ended_on: nil,
               current: true,
             },
             links_hash: {
               role: [
                 non_ministerial_role.content_id,
               ],
             })

      create(:live_edition,
             published_at: "2022-01-05 01:00",
             schema_name: "role_appointment",
             content_store: "live",
             title: "MP 1 - Secretary of State",
             details: {
               started_on: "2021-12-30 00:00",
               ended_on: "2022-01-04 00:00",
               current: false,
             },
             links_hash: {
               role: [
                 ministerial_role_1.content_id,
               ],
             })
    end

    it "includes only records for ministerial role appointments that were updated on or after 2022-01-01" do
      csv = <<~CSV
        name,published_at,started_on,ended_on,current
        "MP 2 - Parliamentary Under Secretary of State",2022-01-01 01:00:00 UTC,2022-01-01 00:00,,true
        "MP 1 - Secretary of State",2022-01-05 01:00:00 UTC,2021-12-30 00:00,2022-01-04 00:00,false
      CSV

      expect { task.invoke("2020-01-01 00:00", "2020-01-04 00:00") }
        .to output(csv).to_stdout
    end
  end
end
