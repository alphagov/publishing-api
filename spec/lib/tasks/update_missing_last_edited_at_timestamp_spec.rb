RSpec.describe "Update missing last_edited_at timestamp for specialist publisher documents" do
  describe "update_missing_last_edited_at_timestamp" do
    let(:task) { Rake::Task["update_missing_last_edited_at_timestamp"] }

    before { task.reenable }

    it "it updates the last_edited_at timestamp" do
      edition_one = create(:edition, schema_name: "specialist_document", document_type: "aaib_report", last_edited_at: nil)
      edition_two = create(:edition, schema_name: "specialist_document", document_type: "cma_case", last_edited_at: nil)
      edition_three = create(:edition, schema_name: "specialist_document", document_type: "aaib_report")
      previous_timestamp = edition_three.last_edited_at

      expect { task.invoke }.to output(<<~PROMETHEUS).to_stdout
        2 editions updated
      PROMETHEUS

      expect(edition_one.reload.last_edited_at).to eq(edition_one.updated_at)
      expect(edition_two.reload.last_edited_at).to eq(edition_two.updated_at)
      expect(edition_three.reload.last_edited_at).to eq(previous_timestamp)
    end
  end
end
